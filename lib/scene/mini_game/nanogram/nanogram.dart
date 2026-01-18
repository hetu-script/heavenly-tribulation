import 'dart:math';

import 'package:flutter/material.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/components.dart';
import 'package:samsara/components/ui/sprite_button.dart';
import 'package:samsara/effect/confetti.dart';

import '../../cursor_state.dart';
import '../../common.dart';
import '../../../ui.dart';
import '../../../global.dart';
import '../../../data/game.dart';

const _kConfettiPriority = 1000;

/// 数织游戏谜题生成器
class _NanogramPuzzle {
  final int rows;
  final int cols;
  late List<List<bool>> solution; // 正确答案
  late List<List<int>> rowHints; // 每行的提示数字
  late List<List<int>> colHints; // 每列的提示数字

  _NanogramPuzzle({
    this.rows = 7,
    this.cols = 11,
  }) {
    solution = List.generate(rows, (_) => List.filled(cols, false));
  }

  /// 生成中心对称的谜题
  void generateCentralSymmetry({int? seed, double fillRate = 0.5}) {
    final random = seed != null ? Random(seed) : Random();

    // 只随机生成一半的格子
    int totalCells = rows * cols;
    for (int i = 0; i < totalCells / 2; i++) {
      int row = i ~/ cols;
      int col = i % cols;

      // 根据填充率决定是否填充
      bool filled = random.nextDouble() < fillRate;
      solution[row][col] = filled;

      // 中心对称镜像
      int mirrorRow = rows - 1 - row;
      int mirrorCol = cols - 1 - col;
      solution[mirrorRow][mirrorCol] = filled;
    }

    // 如果总格子数是奇数，中心点随机
    if (totalCells % 2 == 1) {
      int centerRow = rows ~/ 2;
      int centerCol = cols ~/ 2;
      solution[centerRow][centerCol] = random.nextBool();
    }

    _calculateHints();
  }

  /// 生成水平对称的谜题
  void generateHorizontalSymmetry({int? seed, double fillRate = 0.5}) {
    final random = seed != null ? Random(seed) : Random();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < (cols + 1) ~/ 2; col++) {
        bool filled = random.nextDouble() < fillRate;
        solution[row][col] = filled;
        solution[row][cols - 1 - col] = filled;
      }
    }

    _calculateHints();
  }

  /// 计算提示数字
  void _calculateHints() {
    // 计算每行的提示
    rowHints = [];
    for (int row = 0; row < rows; row++) {
      rowHints.add(_calculateLineHints(solution[row]));
    }

    // 计算每列的提示
    colHints = [];
    for (int col = 0; col < cols; col++) {
      List<bool> column = [];
      for (int row = 0; row < rows; row++) {
        column.add(solution[row][col]);
      }
      colHints.add(_calculateLineHints(column));
    }
  }

  /// 计算单行/列的提示数字
  List<int> _calculateLineHints(List<bool> line) {
    List<int> hints = [];
    int count = 0;

    for (bool cell in line) {
      if (cell) {
        count++;
      } else {
        if (count > 0) {
          hints.add(count);
          count = 0;
        }
      }
    }

    if (count > 0) {
      hints.add(count);
    }

    // 如果整行都是空的，返回 [0]
    if (hints.isEmpty) {
      hints.add(0);
    }

    return hints;
  }

  /// 检查玩家的答案是否正确
  bool checkSolution(List<List<bool>> playerGrid) {
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        if (playerGrid[row][col] != solution[row][col]) {
          return false;
        }
      }
    }
    return true;
  }

  /// 检查玩家的答案是否符合提示（不一定是唯一解）
  bool checkHints(List<List<bool>> playerGrid) {
    // 检查每行
    for (int row = 0; row < rows; row++) {
      List<int> playerRowHints = _calculateLineHints(playerGrid[row]);
      if (!_hintsEqual(playerRowHints, rowHints[row])) {
        return false;
      }
    }

    // 检查每列
    for (int col = 0; col < cols; col++) {
      List<bool> column = [];
      for (int row = 0; row < rows; row++) {
        column.add(playerGrid[row][col]);
      }
      List<int> playerColHints = _calculateLineHints(column);
      if (!_hintsEqual(playerColHints, colHints[col])) {
        return false;
      }
    }

    return true;
  }

  bool _hintsEqual(List<int> hints1, List<int> hints2) {
    if (hints1.length != hints2.length) return false;
    for (int i = 0; i < hints1.length; i++) {
      if (hints1[i] != hints2[i]) return false;
    }
    return true;
  }
}

enum _CellState {
  empty, // 空白
  filled, // 填充
  marked, // 标记为错误
  validatedVacant, // 验证失败（该位置应为空）
}

/// 数织游戏的单个格子
class _NanogramCell extends PositionComponent {
  final int row;
  final int col;

  _CellState _state = _CellState.empty;
  _CellState get state => _state;

  late Sprite coverSprite;
  late Sprite markSprite;
  late Sprite validatedMarkSprite;

  final Function(int row, int col, _CellState newState)? onStateChanged;

  _NanogramCell({
    required this.row,
    required this.col,
    required super.position,
    required super.size,
    this.onStateChanged,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 加载统一的方块贴图
    coverSprite = await Sprite.load('mini_game/nanogram/tile.png');

    // 加载叉号标记贴图
    markSprite = await Sprite.load('mini_game/nanogram/vacant.png');

    // 加载验证失败贴图
    validatedMarkSprite =
        await Sprite.load('mini_game/nanogram/validated_vacant.png');

    // 初始状态：什么都不显示
  }

  /// 设置格子状态
  void setState(_CellState newState) {
    if (_state == newState) return;

    _state = newState;

    onStateChanged?.call(row, col, newState);

    if (_state == _CellState.validatedVacant) {
      engine.play(GameSound.error);
    }
  }

  @override
  void render(Canvas canvas) {
    switch (_state) {
      case _CellState.filled:
        // 显示方块
        coverSprite.render(canvas, size: size);
      case _CellState.marked:
        // 显示叉号
        markSprite.render(canvas, size: size);
      case _CellState.validatedVacant:
        // 显示验证失败提示
        validatedMarkSprite.render(canvas, size: size);
      default:
    }
  }

  /// 重置格子状态
  void reset() {
    setState(_CellState.empty);
  }
}

enum _DragDirection {
  horizontal,
  vertical,
  none,
}

/// 数织游戏的棋盘网格
class _NanogramBoard extends GameComponent with HandlesGesture {
  final _NanogramPuzzle puzzle;
  final List<List<_NanogramCell>> cells = [];
  final Function()? onVictory;

  // 玩家当前的棋盘状态
  late List<List<bool>> playerGrid;

  // 提示数字的文本组件
  final List<TextComponent> rowHintTexts = [];
  final List<TextComponent> colHintTexts = [];

  final Vector2 scaleFactor;
  final Vector2 tileSize;

  // 完成状态追踪
  final Set<int> completedRows = {}; // 已完成的行
  final Set<int> completedCols = {}; // 已完成的列
  final List<RectangleComponent> rowOverlays = []; // 行覆盖层
  final List<RectangleComponent> colOverlays = []; // 列覆盖层

  // 拖动状态追踪
  _NanogramCell? _dragStartCell; // 拖动开始的格子
  _CellState? _dragTargetState; // 拖动时要设置的目标状态
  final List<_NanogramCell> _draggedCells = []; // 已处理的格子（避免重复）
  _DragDirection _dragDirection =
      _DragDirection.none; // 拖动方向锁定 'horizontal', 'vertical', or null
  _NanogramCell? _previousCell; // 上一个处理的格子

  _NanogramBoard({
    required this.puzzle,
    required this.scaleFactor,
    required this.tileSize,
    this.onVictory,
  }) : super(
          position: Vector2(
            GameUI.matchingBoardOffset.x * scaleFactor.x,
            GameUI.matchingBoardOffset.y * scaleFactor.y,
          ),
          size: Vector2(
            tileSize.x * 11,
            tileSize.y * 7,
          ),
        ) {
    enableGesture = true;

    // 鼠标按下事件
    onTapDown = _handleCellClick;

    // 拖动开始
    onDragStart = (button, position) {
      _draggedCells.clear();
      _dragDirection = _DragDirection.none; // 重置方向
      _dragStartCell = null;

      final cellPos = _getCellPosition(position);
      if (cellPos != null) {
        final col = cellPos.$1;
        final row = cellPos.$2;

        // 如果该格子所在的行或列已完成，不允许交互
        if (completedRows.contains(row) || completedCols.contains(col)) {
          return null;
        }

        final cell = cells[row][col];

        if (cell.state == _CellState.filled ||
            cell.state == _CellState.marked) {
          _dragStartCell = cell;

          if (button == kPrimaryButton) {
            _dragTargetState = _CellState.filled;
          } else if (button == kSecondaryButton) {
            _dragTargetState = _CellState.marked;
          }

          _draggedCells.add(cell);
          _previousCell = cell;
        }
      }

      return null;
    };

    // 拖动更新
    onDragUpdate = (button, position, delta) {
      if (_dragTargetState == null || _dragStartCell == null) return;

      // 将全局坐标转换为局部坐标
      final localPos = toLocal(position);
      final cellPos = _getCellPosition(localPos);
      if (cellPos == null) return;

      final col = cellPos.$1;
      final row = cellPos.$2;

      // 如果该格子所在的行或列已完成，跳过
      if (completedRows.contains(row) || completedCols.contains(col)) return;

      final draggingCell = cells[row][col];

      // 如果返回到起始格子，重置方向锁定
      if (draggingCell == _dragStartCell) {
        _dragDirection = _DragDirection.none;
      }

      if (_draggedCells.contains(draggingCell)) {
        if (_previousCell != draggingCell &&
            draggingCell != _draggedCells.last) {
          final index = _draggedCells.indexOf(draggingCell);
          final toBeCanceled =
              _draggedCells.sublist(index + 1, _draggedCells.length);
          for (final cell in toBeCanceled) {
            // 恢复格子到空白状态
            cell.setState(_CellState.empty);
            _draggedCells.remove(cell);
          }
        }

        // 已处理过该格子，跳过
        return;
      } else {
        _previousCell = draggingCell;

        // 确定拖动方向（首次离开起始格子时）
        if (_dragDirection == _DragDirection.none) {
          _dragDirection = _DragDirection.none;
          final startRow = _dragStartCell!.row;
          final startCol = _dragStartCell!.col;

          if (cellPos.$2 == startRow && cellPos.$1 != startCol) {
            // 水平方向（同行不同列）
            _dragDirection = _DragDirection.horizontal;
          } else if (cellPos.$1 == startCol && cellPos.$2 != startRow) {
            // 垂直方向（同列不同行）
            _dragDirection = _DragDirection.vertical;
          } else {
            // 对角线或其他，暂不设置方向
            return;
          }
        }

        // 根据锁定的方向判断是否处理该格子
        if (_dragDirection == _DragDirection.horizontal) {
          // 水平拖动：只处理同行的格子
          if (cellPos.$2 != _dragStartCell!.row) return;
        } else if (_dragDirection == _DragDirection.vertical) {
          // 垂直拖动：只处理同列的格子
          if (cellPos.$1 != _dragStartCell!.col) return;
        }

        _draggedCells.add(draggingCell);

        // 根据答案验证，如果是左键且答案为空，显示错误提示
        if (button == kPrimaryButton && _dragTargetState == _CellState.filled) {
          if (!puzzle.solution[cellPos.$2][cellPos.$1]) {
            draggingCell.setState(_CellState.validatedVacant);
          } else {
            draggingCell.setState(_dragTargetState!);
          }
        } else {
          draggingCell.setState(_dragTargetState!);
        }
      }
    };

    // 拖动结束
    onDragEnd = (position) {
      _draggedCells.clear();
      _dragStartCell = null;
      _dragDirection = _DragDirection.none;
      _dragTargetState = null;
      _previousCell = null;
    };
  }

  /// 根据鼠标位置获取格子坐标 (col, row)
  (int, int)? _getCellPosition(Vector2 localPosition) {
    final col = (localPosition.x / tileSize.x).floor();
    final row = (localPosition.y / tileSize.y).floor();

    if (col >= 0 && col < puzzle.cols && row >= 0 && row < puzzle.rows) {
      return (col, row);
    }
    return null;
  }

  /// 处理格子点击
  void _handleCellClick(int button, Vector2 position) {
    final cellPos = _getCellPosition(position);
    if (cellPos == null) return;

    final col = cellPos.$1;
    final row = cellPos.$2;

    // 如果该格子所在的行或列已完成，不允许交互
    if (completedRows.contains(row) || completedCols.contains(col)) return;

    final cell = cells[row][col];

    if (button == kPrimaryButton) {
      // 左键：切换填充状态
      if (cell.state == _CellState.filled ||
          cell.state == _CellState.validatedVacant) {
        cell.setState(_CellState.empty);
      } else {
        // 检查答案：如果该位置应为空，显示错误提示
        if (!puzzle.solution[row][col]) {
          cell.setState(_CellState.validatedVacant);
        } else {
          cell.setState(_CellState.filled);
        }
      }
    } else if (button == kSecondaryButton) {
      // 右键：切换标记状态
      if (cell.state == _CellState.marked) {
        cell.setState(_CellState.empty);
      } else {
        cell.setState(_CellState.marked);
      }
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 初始化玩家棋盘
    playerGrid = List.generate(
      puzzle.rows,
      (_) => List.filled(puzzle.cols, false),
    );

    // 创建格子
    for (int row = 0; row < puzzle.rows; row++) {
      List<_NanogramCell> rowCells = [];
      for (int col = 0; col < puzzle.cols; col++) {
        final cell = _NanogramCell(
          row: row,
          col: col,
          position: Vector2(
            col * tileSize.x,
            row * tileSize.y,
          ),
          size: tileSize,
          onStateChanged: _onCellStateChanged,
        );

        add(cell);
        rowCells.add(cell);
      }
      cells.add(rowCells);
    }

    // 创建提示数字
    _createHints();
  }

  /// 创建提示数字文本
  void _createHints() {
    // 行提示（左侧，右对齐）
    for (int row = 0; row < puzzle.rows; row++) {
      final hints = puzzle.rowHints[row].join(' ');
      final textComponent = TextBoxComponent(
        text: hints,
        position: Vector2(
          -tileSize.x, // 棋盘左边缘
          row * tileSize.y, // 对应行的中心
        ),
        align: Anchor.centerRight,
        size: tileSize, // 与格子相同大小
        textRenderer: TextPaint(
          style: TextStyle(
            fontFamily: GameUI.fontFamilyBlack,
            fontSize: 16.0,
            color: Colors.yellow,
          ),
        ),
        boxConfig: TextBoxConfig(
          maxWidth: tileSize.x,
        ),
      );
      add(textComponent);
      rowHintTexts.add(textComponent);
    }

    // 列提示（上侧，底部对齐）
    for (int col = 0; col < puzzle.cols; col++) {
      final hints = puzzle.colHints[col].join('\n');
      final textComponent = TextBoxComponent(
        text: hints,
        position: Vector2(
          col * tileSize.x, // 对应列的中心
          -tileSize.y, // 棋盘上边缘
        ),
        align: Anchor.bottomCenter,
        size: tileSize, // 与格子相同大小
        textRenderer: TextPaint(
          style: TextStyle(
            fontFamily: GameUI.fontFamilyBlack,
            fontSize: 16.0,
            color: Colors.yellow,
          ),
        ),
        boxConfig: TextBoxConfig(
          maxWidth: tileSize.x,
        ),
      );
      add(textComponent);
      colHintTexts.add(textComponent);
    }
  }

  /// 当格子状态改变时
  void _onCellStateChanged(int row, int col, _CellState newState) {
    // 更新玩家棋盘
    playerGrid[row][col] = (newState == _CellState.filled);

    // 检查该行和列是否完成（会自动检测游戏胜利）
    _checkRowCompletion(row);
    _checkColCompletion(col);
  }

  /// 检查某一行是否完成
  void _checkRowCompletion(int row) {
    if (completedRows.contains(row)) return; // 已经完成过

    // 检查该行是否符合提示
    List<bool> rowData = playerGrid[row];
    List<int> playerHints = puzzle._calculateLineHints(rowData);

    if (puzzle._hintsEqual(playerHints, puzzle.rowHints[row])) {
      // 该行完成，添加覆盖层
      completedRows.add(row);

      final overlay = RectangleComponent(
        position: Vector2(0, row * tileSize.y),
        size: Vector2(tileSize.x * puzzle.cols, tileSize.y),
        paint: Paint()
          ..color = Color(0x8000FF00) // 半透明绿色
          ..style = PaintingStyle.fill,
      );
      add(overlay);
      rowOverlays.add(overlay);

      engine.play(GameSound.success);

      // 检查游戏是否完成
      _checkCompletion();
    }
  }

  /// 检查某一列是否完成
  void _checkColCompletion(int col) {
    if (completedCols.contains(col)) return; // 已经完成过

    // 检查该列是否符合提示
    List<bool> colData = [];
    for (int row = 0; row < puzzle.rows; row++) {
      colData.add(playerGrid[row][col]);
    }
    List<int> playerHints = puzzle._calculateLineHints(colData);

    if (puzzle._hintsEqual(playerHints, puzzle.colHints[col])) {
      // 该列完成，添加覆盖层
      completedCols.add(col);

      final overlay = RectangleComponent(
        position: Vector2(col * tileSize.x, 0),
        size: Vector2(tileSize.x, tileSize.y * puzzle.rows),
        paint: Paint()
          ..color = Color(0x8000FF00) // 半透明绿色
          ..style = PaintingStyle.fill,
      );
      add(overlay);
      colOverlays.add(overlay);

      engine.play(GameSound.success);

      // 检查游戏是否完成
      _checkCompletion();
    }
  }

  /// 检查游戏是否完成
  void _checkCompletion() {
    // 如果所有行都完成 或 所有列都完成，游戏胜利
    if (completedRows.length == puzzle.rows ||
        completedCols.length == puzzle.cols) {
      onVictory?.call();
    }
  }

  /// 重置棋盘
  void reset() {
    playerGrid = List.generate(
      puzzle.rows,
      (_) => List.filled(puzzle.cols, false),
    );

    for (var row in cells) {
      for (var cell in row) {
        cell.reset();
      }
    }

    // 清除完成状态
    completedRows.clear();
    completedCols.clear();

    // 移除所有覆盖层
    for (var overlay in rowOverlays) {
      overlay.removeFromParent();
    }
    for (var overlay in colOverlays) {
      overlay.removeFromParent();
    }
    rowOverlays.clear();
    colOverlays.clear();
  }

  /// 显示解答（调试用）
  void showSolution() {
    for (int row = 0; row < puzzle.rows; row++) {
      for (int col = 0; col < puzzle.cols; col++) {
        if (puzzle.solution[row][col]) {
          cells[row][col].setState(_CellState.filled);
        } else {
          cells[row][col].setState(_CellState.empty);
        }
      }
    }
  }
}

class NanogramGame extends Scene with HasCursorState {
  late final SpriteComponent _victoryPrompt;
  late final SpriteButton restart, exit;

  late Vector2 _scaleFactor;
  late Vector2 _tileSize;

  _NanogramPuzzle? _currentPuzzle;
  _NanogramBoard? _currentBoard;

  NanogramGame()
      : super(
          id: Scenes.nanogramGame,
        );

  @override
  void onLoad() async {
    super.onLoad();

    _scaleFactor = Vector2(
        size.x / defaultGameSize.width, size.y / defaultGameSize.height);
    _tileSize = Vector2(GameUI.matchingTileSize.x * _scaleFactor.x,
        GameUI.matchingTileSize.y * _scaleFactor.y);

    _victoryPrompt = SpriteComponent(
      anchor: Anchor.center,
      position: Vector2(center.x, center.y - 125),
      sprite: await Sprite.load('ui/victory.png'),
      size: Vector2(480.0, 240.0),
    );

    final background = SpriteComponent(
      sprite: await Sprite.load('mini_game/nanogram/board.png'),
      size: size,
    );
    world.add(background);

    restart = SpriteButton(
      spriteId: 'ui/button2.png',
      size: GameUI.buttonSizeMedium,
      anchor: Anchor.center,
      position: GameUI.restartButtonPosition,
      text: engine.locale('restart'),
    );
    restart.onTap = (_, __) {
      _initializeGame();
    };
    camera.viewport.add(restart);

    exit = SpriteButton(
      spriteId: 'ui/button.png',
      size: GameUI.buttonSizeMedium,
      anchor: Anchor.center,
      position: GameUI.exitButtonPosition,
      text: engine.locale('exit'),
    );
    exit.onTap = (_, __) {
      engine.popScene(clearCache: true);
    };
    camera.viewport.add(exit);

    await _initializeGame();
  }

  Future<void> _initializeGame() async {
    _victoryPrompt.removeFromParent();
    restart.position = GameUI.restartButtonPosition;
    exit.position = GameUI.exitButtonPosition;

    // 移除旧的棋盘
    _currentBoard?.removeFromParent();

    // 生成新谜题（使用中心对称）
    _currentPuzzle = _NanogramPuzzle(rows: 7, cols: 11);
    _currentPuzzle!.generateCentralSymmetry(fillRate: 0.5);

    // 创建棋盘
    _currentBoard = _NanogramBoard(
      puzzle: _currentPuzzle!,
      scaleFactor: _scaleFactor,
      tileSize: _tileSize,
      onVictory: _onGameSuccess,
    );
    world.add(_currentBoard!);
  }

  void _onGameSuccess() {
    engine.play(GameSound.victory);

    camera.viewport.add(_victoryPrompt);

    final celebration = ConfettiEffect(
      size: size,
      priority: _kConfettiPriority,
    );
    camera.viewport.add(celebration);

    restart.position = Vector2(
        center.x,
        _victoryPrompt.bottomRight.y +
            GameUI.buttonSizeMedium.y +
            GameUI.largeIndent);

    exit.position = Vector2(center.x,
        restart.bottomRight.y + GameUI.buttonSizeMedium.y / 2 + GameUI.indent);
  }

  @override
  Widget build(
    BuildContext context, {
    Widget Function(BuildContext)? loadingBuilder,
    Map<String, Widget Function(BuildContext, Scene)>? overlayBuilderMap,
    List<String>? initialActiveOverlays,
  }) {
    return Stack(
      children: [
        SceneWidget(
          scene: this,
          loadingBuilder: loadingBuilder,
          overlayBuilderMap: overlayBuilderMap,
          initialActiveOverlays: initialActiveOverlays,
        ),
        GameUIOverlay(
          enableLibrary: false,
          enableCultivation: false,
          showNpcs: false,
          showJournal: false,
          actions: [
            Container(
              decoration: GameUI.boxDecoration,
              width: GameUI.infoButtonSize.width,
              height: GameUI.infoButtonSize.height,
              child: IconButton(
                icon: Icon(Icons.question_mark),
                padding: const EdgeInsets.all(0),
                mouseCursor: GameUI.cursor.resolve({WidgetState.hovered}),
                onPressed: () {
                  // GameDialogContent.show(
                  //   context,
                  //   engine.locale('hint_cultivation'),
                  //   style: TextStyle(color: Colors.yellow),
                  // );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

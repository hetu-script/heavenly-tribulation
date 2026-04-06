import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/components.dart';
import 'package:samsara/components/ui/sprite_button.dart';
import 'package:samsara/effect/confetti.dart';
import 'package:samsara/components/ui/rich_text_component.dart';
import 'package:samsara/components/sprite_component2.dart';

import '../../cursor_state.dart';
import '../../common.dart';
import '../../../ui.dart';
import '../../../global.dart';
import '../../../data/game.dart';
import '../common.dart';

/// 数织游戏谜题生成器
class _NanogramPuzzle {
  final int rows;
  final int cols;
  late List<List<bool>> solution; // 正确答案
  late List<List<int>> rowHints; // 每行的提示数字
  late List<List<int>> colHints; // 每列的提示数字

  final MiniGameDifficulty difficulty;

  bool isFinished = false;

  _NanogramPuzzle({
    required this.rows,
    required this.cols,
    required this.difficulty,
  }) {
    solution = List.generate(rows, (_) => List.filled(cols, false));

    generate();
  }

  void generate({
    int? seed,
    double blockDensity = 0.7,
  }) {
    final random = seed != null ? math.Random(seed) : math.Random();

    // 根据难度决定唯一解的生成策略
    Set<int> uniqueRows = {};
    Set<int> uniqueCols = {};

    void addUniqueRowAndCol() {
      uniqueRows.add(random.nextInt(rows));
      uniqueCols.add(random.nextInt(cols));
    }

    void addUniqueRowOrCol() {
      if (random.nextBool()) {
        uniqueRows.add(random.nextInt(rows));
      } else {
        uniqueCols.add(random.nextInt(cols));
      }
    }

    void addUniqueRowOrColByNumber(int number) {
      // 随机数量和位置，但至少有一行或一列
      final hasUniqueRow = random.nextBool();
      final hasUniqueCol = random.nextBool();

      if (hasUniqueRow) {
        // 随机0-n个唯一解行
        final count = random.nextInt(number);
        while (uniqueRows.length < count && uniqueRows.length < rows) {
          uniqueRows.add(random.nextInt(rows));
        }
      }
      if (hasUniqueCol) {
        // 随机0-n个唯一解列
        final count = random.nextInt(number);
        while (uniqueCols.length < count && uniqueCols.length < cols) {
          uniqueCols.add(random.nextInt(cols));
        }
      }
    }

    late int maxHints;
    switch (difficulty) {
      case MiniGameDifficulty.easy:
        maxHints = 3;
        addUniqueRowAndCol();
      case MiniGameDifficulty.normal:
        maxHints = 4;
        addUniqueRowAndCol();
        addUniqueRowOrColByNumber(3);
      case MiniGameDifficulty.challenging:
        maxHints = 4;
        addUniqueRowOrCol();
        addUniqueRowOrColByNumber(2);
      case MiniGameDifficulty.hard:
        maxHints = 5;
        addUniqueRowOrCol();
        addUniqueRowOrColByNumber(3);
      case MiniGameDifficulty.tough:
        maxHints = 5;
        addUniqueRowOrCol();
        addUniqueRowOrColByNumber(2);
      case MiniGameDifficulty.brutal:
        maxHints = 5;
    }

    // 为每行生成方块
    for (int row = 0; row < rows; row++) {
      if (uniqueRows.contains(row)) {
        // 生成唯一解行
        final patterns = _getUniquePatterns(cols);
        // 过滤出符合最大提示数字数量限制的模式
        final validPatterns =
            patterns.where((p) => p.length <= maxHints).toList();
        if (validPatterns.isEmpty) {
          // 如果没有有效模式，使用普通生成
          _generateNormalRow(row, random, blockDensity, maxHints);
        } else {
          final pattern = validPatterns[random.nextInt(validPatterns.length)];
          int col = 0;
          for (final blockSize in pattern) {
            for (int i = 0; i < blockSize; i++) {
              solution[row][col++] = true;
            }
            if (col < cols) col++; // 空格
          }
        }
      } else {
        // 生成普通行（限制块数量）
        _generateNormalRow(row, random, blockDensity, maxHints);
      }
    }

    // 4. 为唯一解列调整生成，使其符合唯一解模式
    for (final col in uniqueCols) {
      final patterns = _getUniquePatterns(rows);
      // 过滤出符合最大提示数字数量限制的模式
      final validPatterns =
          patterns.where((p) => p.length <= maxHints).toList();

      if (validPatterns.isEmpty) {
        // 如果没有有效模式，使用普通生成
        _generateNormalColumn(col, random, blockDensity, maxHints);
      } else {
        final pattern = validPatterns[random.nextInt(validPatterns.length)];

        // 清空该列
        for (int row = 0; row < rows; row++) {
          solution[row][col] = false;
        }

        // 按照唯一解模式填充
        int row = 0;
        for (final blockSize in pattern) {
          for (int i = 0; i < blockSize; i++) {
            solution[row++][col] = true;
          }
          if (row < rows) row++; // 空格
        }
      }
    }

    // 5. 检查所有列，确保提示数字数量不超过限制
    for (int col = 0; col < cols; col++) {
      if (uniqueCols.contains(col)) continue; // 唯一解列已经处理过

      // 提取该列数据
      List<bool> colData = [];
      for (int row = 0; row < rows; row++) {
        colData.add(solution[row][col]);
      }

      // 检查提示数字数量
      final hints = _calculateLineHints(colData);
      if (hints.length > maxHints || (hints.length == 1 && hints.first == 0)) {
        // 超过限制或全空，重新生成该列
        _generateNormalColumn(col, random, blockDensity, maxHints);
      }
    }

    _calculateHints();
  }

  /// 生成普通行（限制块数量）
  void _generateNormalRow(
      int row, math.Random random, double blockDensity, int maxHints) {
    int attempts = 0;
    while (attempts < 100) {
      // 清空该行
      for (int col = 0; col < cols; col++) {
        solution[row][col] = false;
      }

      // 生成随机块
      bool inBlock = false;
      for (int col = 0; col < cols; col++) {
        if (inBlock) {
          solution[row][col] = random.nextDouble() < blockDensity;
          if (!solution[row][col]) inBlock = false;
        } else {
          solution[row][col] = random.nextDouble() < 0.5;
          if (solution[row][col]) inBlock = true;
        }
      }

      // 检查提示数字数量
      final hints = _calculateLineHints(solution[row]);
      if (hints.length <= maxHints && hints.first != 0) {
        return; // 符合条件，结束
      }
      attempts++;
    }
    // 如果100次都不符合，强制生成一个简单的模式
    for (int col = 0; col < cols; col++) {
      solution[row][col] = false;
    }
    solution[row][0] = true; // 至少有一个块
  }

  /// 生成普通列（限制块数量）
  void _generateNormalColumn(
      int col, math.Random random, double blockDensity, int maxHints) {
    int attempts = 0;
    while (attempts < 100) {
      // 清空该列
      for (int row = 0; row < rows; row++) {
        solution[row][col] = false;
      }

      // 生成随机块
      bool inBlock = false;
      for (int row = 0; row < rows; row++) {
        if (inBlock) {
          solution[row][col] = random.nextDouble() < blockDensity;
          if (!solution[row][col]) inBlock = false;
        } else {
          solution[row][col] = random.nextDouble() < 0.5;
          if (solution[row][col]) inBlock = true;
        }
      }

      // 检查提示数字数量
      List<bool> colData = [];
      for (int row = 0; row < rows; row++) {
        colData.add(solution[row][col]);
      }
      final hints = _calculateLineHints(colData);
      if (hints.length <= maxHints && hints.first != 0) {
        return; // 符合条件，结束
      }
      attempts++;
    }
    // 如果100次都不符合，强制生成一个简单的模式
    for (int row = 0; row < rows; row++) {
      solution[row][col] = false;
    }
    solution[0][col] = true; // 至少有一个块
  }

// 获取唯一解模式
  List<List<int>> _getUniquePatterns(int length) {
    final patterns = <List<int>>[];

    // (length) - 整行填满
    patterns.add([length]);

    // (1, length-2, 1) 等各种组合...
    for (int a = 1; a < length - 1; a++) {
      for (int b = 1; b < length - a; b++) {
        // 检查是否唯一：a + b + 间隔数 == length
        int gaps = 1; // a和b之间至少1个空格
        if (a + b + gaps == length) {
          patterns.add([a, b]);
        }
      }
    }

    return patterns;
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
  unknown, // 未知
  filled, // 方块
  vacant, // 空位
}

/// 数织游戏的单个格子
class _NanogramCell extends PositionComponent {
  static final _shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.6)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8.0
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;

  static final _filledPaint = Paint()
    ..color = Colors.lightGreen
    ..style = PaintingStyle.fill;

  static final _errorFilledPaint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.fill;

  static final _vacantPaint = Paint()
    ..color = Colors.lightGreen
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6.0
    ..strokeCap = StrokeCap.round;

  static final _errorVacantPaint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6.0
    ..strokeCap = StrokeCap.round;

  final int row;
  final int col;

  _CellState _state = _CellState.unknown;
  _CellState get state => _state;

  final Function(int row, int col, _CellState newState)? onStateChanged;

  late final RRect shadowBounds, fillBounds, errorHintBounds;
  late Offset x1, y1, x2, y2;

  bool isError = false;

  _NanogramCell({
    required this.row,
    required this.col,
    required super.position,
    required super.size,
    this.onStateChanged,
  }) {
    final padding1 = size * 0.15;
    final rect = Rect.fromLTWH(padding1.x, padding1.y, size.x - 2 * padding1.x,
        size.y - 2 * padding1.y);

    shadowBounds = RRect.fromRectAndRadius(
      rect.inflate(1),
      Radius.circular(8.0),
    );

    fillBounds = RRect.fromRectAndRadius(
      rect,
      Radius.circular(8.0),
    );

    errorHintBounds = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.x - 4, size.y - 4),
      Radius.circular(8.0),
    );

    final padding2 = size * 0.25;
    x1 = Offset(padding2.x, padding2.y);
    y1 = Offset(size.x - padding2.x, size.y - padding2.y);
    x2 = Offset(size.x - padding2.x, padding2.y);
    y2 = Offset(padding2.x, size.y - padding2.y);
  }

  /// 设置格子状态
  void setState(_CellState newState, {bool isError = false}) {
    if (_state == newState) return;

    engine.play(GameSound.click);

    _state = newState;

    if (isError) {
      this.isError = true;
      engine.play(GameSound.error);
    }

    onStateChanged?.call(row, col, newState);
  }

  @override
  void render(Canvas canvas) {
    // if (isError) {
    //   canvas.drawRRect(errorHintBounds, _errorPaint);
    // }

    switch (_state) {
      case _CellState.filled:
        canvas.drawRRect(shadowBounds, _shadowPaint);
        canvas.drawRRect(
            fillBounds, isError ? _errorFilledPaint : _filledPaint);
      case _CellState.vacant:
        canvas.drawLine(x1, y1, _shadowPaint);
        canvas.drawLine(x2, y2, _shadowPaint);
        canvas.drawLine(x1, y1, isError ? _errorVacantPaint : _vacantPaint);
        canvas.drawLine(x2, y2, isError ? _errorVacantPaint : _vacantPaint);
      default:
    }
  }

  /// 重置格子状态
  void reset() {
    setState(_CellState.unknown);
  }
}

enum _DragDirection {
  horizontal,
  vertical,
  none,
}

/// 数织游戏的棋盘网格
class _NanogramBoard extends GameComponent with HandlesGesture {
  static final _shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.6)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8.0
    ..isAntiAlias = true;

  static final _outerStrokePaint = Paint()
    ..color = Colors.black87
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6.0
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;

  static final _innerStrokePaint = Paint()
    ..color = Colors.white70
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;

  static final _completionHintPaint = Paint()
    ..color = Colors.yellow.withValues(alpha: 0.5)
    ..style = PaintingStyle.fill;

  static final _hoverHintPaint = Paint()
    ..color = Colors.blue.withValues(alpha: 0.15)
    ..style = PaintingStyle.fill;

  // 提示文字样式（基础，实际使用时会根据tileSize调整fontSize）
  static TextStyle _hintTextStyle(double tileSize) => TextStyle(
        fontFamily: GameUI.fontFamilyBlack,
        fontWeight: FontWeight.bold,
        fontSize: (tileSize * 0.35).clamp(12.0, 24.0), // 动态计算字体大小
        color: Colors.white,
      );

  final _NanogramPuzzle puzzle;
  final List<List<_NanogramCell>> cells = [];
  final Function()? onVictory;

  // 玩家当前的棋盘状态
  late List<List<bool>> playerGrid;

  // 提示数字的文本组件
  final List<RichTextComponent> hintTexts = [];

  // 每行/列已完成的hint索引集合 (用于绿色高亮)
  final List<Set<int>> completedRowHints =
      []; // completedRowHints[row] = {0, 2} 表示该行第0和第2个hint已完成
  final List<Set<int>> completedColHints = [];

  final Vector2 tileSize;

  // 完成状态追踪
  final Set<int> completedRows = {}; // 已完成的行
  final Set<int> completedCols = {}; // 已完成的列
  final List<RectangleComponent> rowOverlays = []; // 行覆盖层
  final List<RectangleComponent> colOverlays = []; // 列覆盖层

  // 鼠标悬停高亮
  RectangleComponent? _hoverRowHighlight;
  RectangleComponent? _hoverColHighlight;
  int? _currentHoverRow;
  int? _currentHoverCol;

  // 拖动状态追踪
  _NanogramCell? _dragStartCell; // 拖动开始的格子
  _CellState? _dragTargetState; // 拖动时要设置的目标状态
  final List<_NanogramCell> _draggedCells = []; // 已处理的格子（避免重复）
  _DragDirection _dragDirection =
      _DragDirection.none; // 拖动方向锁定 'horizontal', 'vertical', or null
  _NanogramCell? _previousCell; // 上一个处理的格子

  void Function()? onError;

  _NanogramBoard({
    required this.puzzle,
    required super.position,
    required this.tileSize,
    this.onVictory,
    super.anchor,
    this.onError,
  }) : super(
            size: Vector2(tileSize.x * puzzle.cols, tileSize.y * puzzle.rows)) {
    enableGesture = true;

    // 鼠标按下事件
    onTapDown = (int button, Vector2 position) {
      if (puzzle.isFinished) return;

      final cellPos = _getCellPosition(position);
      if (cellPos == null) return;

      final col = cellPos.$1;
      final row = cellPos.$2;

      // if (completedRows.contains(row) || completedCols.contains(col)) return;

      final cell = cells[row][col];
      // 如果该格子已被标记，不允许交互
      if (cell.state != _CellState.unknown) return;

      if (button == kPrimaryButton) {
        _trySetCellState(cell, _CellState.filled);
      } else if (button == kSecondaryButton) {
        _trySetCellState(cell, _CellState.vacant);
      }
    };

    // 拖动开始
    onDragStart = (button, position) {
      if (puzzle.isFinished) return;

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
            cell.state == _CellState.vacant) {
          _dragStartCell = cell;

          if (button == kPrimaryButton) {
            _dragTargetState = _CellState.filled;
          } else if (button == kSecondaryButton) {
            _dragTargetState = _CellState.vacant;
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
            cell.setState(_CellState.unknown);
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

        if (button == kPrimaryButton) {
          _trySetCellState(draggingCell, _CellState.filled);
        } else if (button == kSecondaryButton) {
          _trySetCellState(draggingCell, _CellState.vacant);
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

    // 鼠标悬停
    onMouseHover = (position) {
      final cellPos = _getCellPosition(position);
      if (cellPos != null) {
        final col = cellPos.$1;
        final row = cellPos.$2;
        _updateHoverHighlight(row, col);
      } else {
        _clearHoverHighlight();
      }
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

  /// 更新鼠标悬停高亮
  void _updateHoverHighlight(int row, int col) {
    if (_currentHoverRow == row && _currentHoverCol == col) return;

    _currentHoverRow = row;
    _currentHoverCol = col;

    // 移除旧的高亮
    _hoverRowHighlight?.removeFromParent();
    _hoverColHighlight?.removeFromParent();

    // 创建新的行高亮
    _hoverRowHighlight = RectangleComponent(
      position: Vector2(0, row * tileSize.y),
      size: Vector2(tileSize.x * puzzle.cols, tileSize.y),
      paint: _hoverHintPaint,
      priority: -200, // 在完成提示覆盖层下面
    );
    add(_hoverRowHighlight!);

    // 创建新的列高亮
    _hoverColHighlight = RectangleComponent(
      position: Vector2(col * tileSize.x, 0),
      size: Vector2(tileSize.x, tileSize.y * puzzle.rows),
      paint: _hoverHintPaint,
      priority: -200, // 在完成提示覆盖层下面
    );
    add(_hoverColHighlight!);
  }

  /// 清除鼠标悬停高亮
  void _clearHoverHighlight() {
    _currentHoverRow = null;
    _currentHoverCol = null;
    _hoverRowHighlight?.removeFromParent();
    _hoverColHighlight?.removeFromParent();
    _hoverRowHighlight = null;
    _hoverColHighlight = null;
  }

  /// 检查答案，并显示错误提示
  void _trySetCellState(_NanogramCell cell, _CellState state) {
    if (state == _CellState.filled) {
      if (puzzle.solution[cell.row][cell.col]) {
        cell.setState(_CellState.filled);
      } else {
        onError?.call();
        cell.setState(_CellState.vacant, isError: true);
      }
    } else if (state == _CellState.vacant) {
      if (puzzle.solution[cell.row][cell.col]) {
        onError?.call();
        cell.setState(_CellState.filled, isError: true);
      } else {
        cell.setState(_CellState.vacant);
      }
    } else {
      cell.setState(_CellState.unknown);
    }
  }

  void _drawLine(Canvas canvas, Offset start, Offset end) {
    // 1. 绘制阴影
    canvas.drawLine(start, end, _shadowPaint);
    // 2. 绘制外层黑色描边
    canvas.drawLine(start, end, _outerStrokePaint);
    // 3. 绘制内层白色线条
    canvas.drawLine(start, end, _innerStrokePaint);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 绘制网格线
    for (int row = 0; row <= puzzle.rows; row++) {
      final y = row * tileSize.y;
      _drawLine(canvas, Offset(0, y), Offset(size.x, y));
    }

    for (int col = 0; col <= puzzle.cols; col++) {
      final x = col * tileSize.x;
      _drawLine(canvas, Offset(x, 0), Offset(x, size.y));
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

    // 初始化已完成hint追踪
    for (int i = 0; i < puzzle.rows; i++) {
      completedRowHints.add({});
    }
    for (int i = 0; i < puzzle.cols; i++) {
      completedColHints.add({});
    }

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
    final hintStyle = _hintTextStyle(tileSize.x);

    // 行提示（左侧，右对齐）
    for (int row = 0; row < puzzle.rows; row++) {
      final hints = puzzle.rowHints[row].join(' ');
      final boxSize = Vector2(tileSize.x * 2, tileSize.y);
      final textComponent = RichTextComponent(
        text: hints,
        anchor: Anchor.topRight,
        position: Vector2(
          -GameUI.smallIndent,
          row * tileSize.y,
        ),
        size: boxSize,
        config: ScreenTextConfig(
          outlined: true,
          size: boxSize,
          anchor: Anchor.centerRight,
          textStyle: hintStyle,
        ),
      );
      add(textComponent);
      hintTexts.add(textComponent);
    }

    // 列提示（上侧，底部对齐）
    for (int col = 0; col < puzzle.cols; col++) {
      final hints = puzzle.colHints[col].join('\n');
      final boxSize = Vector2(tileSize.x, tileSize.y * 2);
      final textComponent = RichTextComponent(
        text: hints,
        anchor: Anchor.bottomLeft,
        position: Vector2(
          col * tileSize.x,
          -GameUI.smallIndent,
        ),
        size: boxSize,
        config: ScreenTextConfig(
          outlined: true,
          size: boxSize,
          anchor: Anchor.bottomCenter,
          textStyle: hintStyle,
        ),
      );
      add(textComponent);
      hintTexts.add(textComponent);
    }
  }

  /// 当格子状态改变时
  void _onCellStateChanged(int row, int col, _CellState newState) {
    // 更新玩家棋盘
    playerGrid[row][col] = (newState == _CellState.filled);

    // 更新hint颜色
    _updateHintColors(row, col);

    // 检查该行和列是否完成（会自动检测游戏胜利）
    _checkRowCompletion(row);
    _checkColCompletion(col);
  }

  /// 更新提示数字的颜色（绿色表示已正确完成）
  void _updateHintColors(int row, int col) {
    // 检查该行的hints
    final rowHintsCompleted = _checkLineHintsCompletion(
      playerGrid[row],
      puzzle.solution[row],
      puzzle.rowHints[row],
    );

    if (!_setsEqual(completedRowHints[row], rowHintsCompleted)) {
      completedRowHints[row] = rowHintsCompleted;
      _updateRowHintText(row);
    }

    // 检查该列的hints
    List<bool> colPlayerData = [];
    List<bool> colSolutionData = [];
    for (int r = 0; r < puzzle.rows; r++) {
      colPlayerData.add(playerGrid[r][col]);
      colSolutionData.add(puzzle.solution[r][col]);
    }

    final colHintsCompleted = _checkLineHintsCompletion(
      colPlayerData,
      colSolutionData,
      puzzle.colHints[col],
    );

    if (!_setsEqual(completedColHints[col], colHintsCompleted)) {
      completedColHints[col] = colHintsCompleted;
      _updateColHintText(col);
    }
  }

  /// 检查一行/列中哪些hint已经完成（玩家填的和答案一致）
  Set<int> _checkLineHintsCompletion(
    List<bool> playerLine,
    List<bool> solutionLine,
    List<int> hints,
  ) {
    Set<int> completed = {};

    // 提取玩家填的连续块
    List<(int start, int length)> playerBlocks = [];
    int start = -1;
    for (int i = 0; i < playerLine.length; i++) {
      if (playerLine[i]) {
        if (start == -1) start = i;
      } else {
        if (start != -1) {
          playerBlocks.add((start, i - start));
          start = -1;
        }
      }
    }
    if (start != -1) {
      playerBlocks.add((start, playerLine.length - start));
    }

    // 提取答案的连续块
    List<(int start, int length)> solutionBlocks = [];
    start = -1;
    for (int i = 0; i < solutionLine.length; i++) {
      if (solutionLine[i]) {
        if (start == -1) start = i;
      } else {
        if (start != -1) {
          solutionBlocks.add((start, i - start));
          start = -1;
        }
      }
    }
    if (start != -1) {
      solutionBlocks.add((start, solutionLine.length - start));
    }

    // 比对每个hint对应的块
    for (int hintIdx = 0;
        hintIdx < hints.length && hintIdx < solutionBlocks.length;
        hintIdx++) {
      if (hints[hintIdx] == 0) continue; // 跳过空行标记

      final solutionBlock = solutionBlocks[hintIdx];

      // 在玩家的块中查找匹配的
      for (final playerBlock in playerBlocks) {
        if (playerBlock.$1 == solutionBlock.$1 &&
            playerBlock.$2 == solutionBlock.$2) {
          // 位置和长度都匹配，说明这个hint已完成
          completed.add(hintIdx);
          break;
        }
      }
    }

    return completed;
  }

  bool _setsEqual(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }

  /// 更新某一行的hint文本
  void _updateRowHintText(int row) {
    final hints = puzzle.rowHints[row];
    final completedSet = completedRowHints[row];

    String text = '';
    for (int i = 0; i < hints.length; i++) {
      if (i > 0) text += ' ';
      if (completedSet.contains(i)) {
        text += '<green>${hints[i]}</>';
      } else {
        text += '${hints[i]}';
      }
    }

    // 更新对应的RichTextComponent
    final textComponent = hintTexts[row];
    textComponent.text = text;
  }

  /// 更新某一列的hint文本
  void _updateColHintText(int col) {
    final hints = puzzle.colHints[col];
    final completedSet = completedColHints[col];

    String text = '';
    for (int i = 0; i < hints.length; i++) {
      if (i > 0) text += '\n';
      if (completedSet.contains(i)) {
        text += '<green>${hints[i]}</>';
      } else {
        text += '${hints[i]}';
      }
    }

    // 列的hint在行hints之后，索引需要偏移
    final textComponent = hintTexts[puzzle.rows + col];
    textComponent.text = text;
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

      // 自动设置该行所有格子为正确状态
      for (int col = 0; col < puzzle.cols; col++) {
        final cell = cells[row][col];
        final correctState =
            puzzle.solution[row][col] ? _CellState.filled : _CellState.vacant;
        if (cell.state != correctState) {
          cell._state = correctState;
        }
      }

      final completionHint = RectangleComponent(
        position: Vector2(0, row * tileSize.y),
        size: Vector2(tileSize.x * puzzle.cols, tileSize.y),
        paint: _completionHintPaint,
        priority: -100, // 确保覆盖层在最底层
      );
      add(completionHint);
      rowOverlays.add(completionHint);

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

      // 自动设置该列所有格子为正确状态
      for (int row = 0; row < puzzle.rows; row++) {
        final cell = cells[row][col];
        final correctState =
            puzzle.solution[row][col] ? _CellState.filled : _CellState.vacant;
        if (cell.state != correctState) {
          cell._state = correctState;
        }
      }

      final overlay = RectangleComponent(
        position: Vector2(col * tileSize.x, 0),
        size: Vector2(tileSize.x, tileSize.y * puzzle.rows),
        paint: _completionHintPaint,
        priority: -100, // 确保覆盖层在最底层
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

    // 清除hint完成追踪
    for (var set in completedRowHints) {
      set.clear();
    }
    for (var set in completedColHints) {
      set.clear();
    }

    // 重置hint文本颜色
    for (int row = 0; row < puzzle.rows; row++) {
      _updateRowHintText(row);
    }
    for (int col = 0; col < puzzle.cols; col++) {
      _updateColHintText(col);
    }

    // 移除所有覆盖层
    for (var overlay in rowOverlays) {
      overlay.removeFromParent();
    }
    for (var overlay in colOverlays) {
      overlay.removeFromParent();
    }
    rowOverlays.clear();
    colOverlays.clear();

    // 清除悬停高亮
    _clearHoverHighlight();
  }

  /// 显示解答
  void showSolution() {
    for (int row = 0; row < puzzle.rows; row++) {
      for (int col = 0; col < puzzle.cols; col++) {
        if (puzzle.solution[row][col]) {
          cells[row][col].setState(_CellState.filled);
        } else {
          cells[row][col].setState(_CellState.unknown);
        }
      }
    }
  }
}

class NanogramGame extends Scene with HasCursorState {
  final MiniGameDifficulty difficulty;

  late final SpriteComponent _victoryPrompt, _defeatPrompt;
  late final SpriteButton restart, exit;

  late final Sprite heart, brokenHeart;

  _NanogramPuzzle? _currentPuzzle;
  _NanogramBoard? _currentBoard;

  bool isGameOver = false;
  bool isGameWon = false;

  late final SpriteComponent2 barrier;

  int _errorCount = 0;

  FutureOr<void> Function()? onGameStart;
  FutureOr<dynamic> Function(bool won)? onGameEnd;

  NanogramGame({
    required this.difficulty,
    this.onGameStart,
    this.onGameEnd,
  }) : super(
          id: Scenes.nanogramGame,
          bgm: engine.bgm,
          bgmFile: 'whisper-of-empty-mountains-428655.mp3',
          bgmVolume: 0.5,
        );

  @override
  void onLoad() async {
    super.onLoad();

    // _scaleFactor = Vector2(
    //     size.x / defaultGameSize.width, size.y / defaultGameSize.height);
    // _tileSize现在在_initializeGame中根据棋盘大小动态计算

    heart = await Sprite.load('mini_game/heart.png');
    brokenHeart = await Sprite.load('mini_game/broken_heart.png');

    barrier = SpriteComponent2(
      size: size,
      color: GameUI.barrierColor,
      priority: 10000,
      isVisible: false,
    );
    world.add(barrier);

    _victoryPrompt = SpriteComponent(
      anchor: Anchor.center,
      position: Vector2(center.x, center.y - 125),
      sprite: await Sprite.load('ui/victory.png'),
      size: Vector2(480.0, 240.0),
    );
    _defeatPrompt = SpriteComponent(
      anchor: Anchor.center,
      position: Vector2(center.x, center.y - 125),
      sprite: await Sprite.load('ui/defeat.png'),
      size: Vector2(480.0, 240.0),
    );

    // 使用纯色背景代替图片
    final background = SpriteComponent(
      sprite: await Sprite.load('mini_game/background2.png'),
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
    restart.isVisible = engine.config.debugMode;
    camera.viewport.add(restart);

    exit = SpriteButton(
      spriteId: 'ui/button.png',
      size: GameUI.buttonSizeMedium,
      anchor: Anchor.center,
      position: GameUI.exitButtonPosition,
      text: engine.locale('exit'),
    );
    exit.onTap = (_, __) {
      _endScene(isGameWon);
    };
    camera.viewport.add(exit);

    await _initializeGame();
  }

  Future<void> _initializeGame() async {
    engine.bgm.resume();

    _errorCount = 0;
    isGameOver = false;
    barrier.isVisible = false;

    _victoryPrompt.removeFromParent();
    _defeatPrompt.removeFromParent();

    restart.position = GameUI.restartButtonPosition;
    exit.position = GameUI.exitButtonPosition;

    restart.isVisible = engine.config.debugMode;

    // 移除旧的棋盘
    _currentBoard?.removeFromParent();

    // 根据难度设置棋盘大小
    int puzzleSize = switch (difficulty) {
      MiniGameDifficulty.easy => 5,
      MiniGameDifficulty.medium => 10,
      MiniGameDifficulty.hard => 15,
    };

    // 生成新谜题（使用中心对称）
    _currentPuzzle = _NanogramPuzzle(
        rows: puzzleSize, cols: puzzleSize, difficulty: difficulty);

    // 动态计算tileSize以适应屏幕和提示
    // 可用空间 = 屏幕大小 - 上下边距
    final availableWidth = size.x - GameUI.largeIndent * 2;
    final availableHeight =
        size.y - GameUI.miniGameTopBarHeight - GameUI.largeIndent;

    // 提示区域：左侧2个tileSize，上方2个tileSize
    // 总需求 = (puzzleSize + 2) * tileSize
    final maxTileSizeWidth = availableWidth / (puzzleSize + 2);
    final maxTileSizeHeight = availableHeight / (puzzleSize + 2);

    // 取较小值确保不会溢出
    final calculatedTileSize = math.min(maxTileSizeWidth, maxTileSizeHeight);
    final tileSize = Vector2(calculatedTileSize, calculatedTileSize);

    // 创建棋盘
    _currentBoard = _NanogramBoard(
      anchor: Anchor.center,
      position: Vector2(center.x, center.y + GameUI.hugeIndent),
      puzzle: _currentPuzzle!,
      tileSize: tileSize,
      onVictory: () => _onGameOver(true),
      onError: _onError,
    );
    world.add(_currentBoard!);

    await onGameStart?.call();
  }

  void _onError() {
    ++_errorCount;
    if (_errorCount >= kMiniGameMaxErrors) {
      _onGameOver(false);
    }

    // 播放失败音效
    engine.play(GameSound.error);
  }

  void _onGameOver(bool won) {
    if (isGameOver) return;

    engine.bgm.pause();

    isGameOver = true;
    isGameWon = won;
    barrier.isVisible = true;

    _currentPuzzle?.isFinished = true;

    if (won) {
      camera.viewport.add(_victoryPrompt);
      engine.play(GameSound.victory);

      final celebration = ConfettiEffect(
        position: Vector2.zero(),
        size: size,
        priority: kConfettiPriority,
      );
      camera.viewport.add(celebration);
    } else {
      camera.viewport.add(_defeatPrompt);
      engine.play(GameSound.gameOver);
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      restart.isVisible = engine.config.debugMode;
      restart.position = Vector2(
          center.x,
          _victoryPrompt.bottomRight.y +
              GameUI.buttonSizeMedium.y +
              GameUI.largeIndent);

      exit.position = Vector2(
          center.x,
          restart.bottomRight.y +
              GameUI.buttonSizeMedium.y / 2 +
              GameUI.indent);
    });
  }

  Future<void> _endScene(bool won) async {
    final result = await onGameEnd?.call(won);
    if (result != true) {
      engine.popScene(clearCache: true);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final startPoint2 = GameUI.errorCountIndicatorsPosition.clone();
    for (var i = 0; i < kMiniGameMaxErrors; ++i) {
      if (i < kMiniGameMaxErrors - _errorCount) {
        heart.render(
          canvas,
          position: startPoint2,
          size: Vector2.all(GameUI.miniGameIndicatorIconSize),
        );
      } else {
        brokenHeart.render(
          canvas,
          position: startPoint2,
          size: Vector2.all(GameUI.miniGameIndicatorIconSize),
        );
      }
      startPoint2.x += GameUI.miniGameIndicatorIconSize;
    }
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

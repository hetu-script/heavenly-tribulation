import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/cardgame/zones/piled_zone.dart';
import 'package:samsara/components/sprite_component2.dart';
import 'package:samsara/hover_info.dart';
import 'package:samsara/samsara.dart';

import '../../data/game.dart';
import '../../global.dart';
import '../../logic/logic.dart';
import '../../state/states.dart';
import '../../ui.dart';
import '../common.dart';
import '../cursor_state.dart';
import '../world/widgets/drop_menu.dart';
import '../../widgets/dialog/confirm.dart';
import 'dungeon_controller.dart';
import 'scavenge.dart';

class DungeonScene extends Scene with HasCursorState {
  DungeonScene() : super(id: Scenes.dungeon);

  late final SpriteComponent2 _backgroundComponent;
  late final PiledZone _siteList;
  final List<dynamic> _navigationCards = [];
  final ValueNotifier<bool> _scavengeVisible = ValueNotifier(false);
  DungeonScavengeComponent? _scavenge;

  int get _development => GameData.hero['rank'] as int? ?? 0;

  void _onPreviewSiteCard() {
    cursorState = MouseCursorState.click;
    engine.context.read<HoverContentState>().hide();
  }

  void _onUnpreviewSiteCard() {
    cursorState = MouseCursorState.normal;
  }

  void _addSiteCard({
    required String id,
    required String title,
    required String image,
    Vector2? position,
    bool inPile = true,
    required FutureOr<void> Function() onTap,
  }) {
    final card = GameData.createSiteCard(
      id: id,
      spriteId: 'dungeon/card/$image.jpg',
      title: title,
      position: position,
      onPreviewed: _onPreviewSiteCard,
      onUnpreviewed: _onUnpreviewSiteCard,
    );
    card.onTap = (_, __) async {
      if (_scavenge != null) return;
      await onTap();
    };
    if (inPile) _siteList.tryAddCard(card);
    _navigationCards.add(card);
    world.add(card);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    _backgroundComponent = SpriteComponent2(
      sprite: await Sprite.load('dungeon/background/spellcraft_gate.jpg'),
      size: size,
    );
    _backgroundComponent.onTapDown = (_, __) {
      engine.context.read<HoverContentState>().hide();
    };
    world.add(_backgroundComponent);

    _siteList = PiledZone(
      position: GameUI.siteListPosition,
      pileStyle: PileStyle.queue,
      piledCardSize: GameUI.siteCardSize,
      pileOffset: Vector2(GameUI.siteCardSize.x / 2, 0),
      spreadOnFocus: true,
      spreadMargin: GameUI.siteCardSize.x / 2,
    );
    world.add(_siteList);
  }

  Future<void> _showCurrentRoom() async {
    final scene = DungeonController.currentScene;
    final room = DungeonController.currentRoom;
    assert(scene != null && room != null);

    _backgroundComponent.sprite = await Sprite.load(scene['background']);
    for (final card in _navigationCards) {
      card.removeFromParent();
    }
    _navigationCards.clear();
    _siteList.cards.clear();

    final actor = room['actor'];
    gameState.updateNpcs([if (actor != null) actor]);
    gameState.updateDungeon(DungeonController.run);

    final route = DungeonController.currentRoute;
    final sceneIds = route['sceneIds'] as List;
    final index = DungeonController.run['currentSceneIndex'] as int;
    if (DungeonController.canGoNext() && index + 1 < sceneIds.length) {
      _addSiteCard(
        id: 'next_room',
        title: engine.locale('nextRoom'),
        image: 'advance',
        onTap: () async {
          DungeonController.goToRoom(index + 1);
          await _showCurrentRoom();
        },
      );
    }
    final canReturnCamp = DungeonController.canReturnCamp();
    if (index > 0) {
      _addSiteCard(
        id: 'previous_room',
        title: engine.locale('previousRoom'),
        image: 'previous_room',
        position: canReturnCamp ? null : GameUI.siteExitCardPositon,
        inPile: canReturnCamp,
        onTap: () async {
          DungeonController.goToRoom(index - 1);
          await _showCurrentRoom();
        },
      );
    }
    if (canReturnCamp) {
      _addSiteCard(
        id: 'return_camp',
        title: engine.locale('returnCamp'),
        image: 'camp_start',
        position: GameUI.siteExitCardPositon,
        inPile: false,
        onTap: () => _finishRunAndReturn('victory'),
      );
    }
    _siteList.sortCards(animated: false);
  }

  Future<void> _onNpcInteract(dynamic actor) async {
    if (_scavenge != null) return;
    final scene = DungeonController.currentScene;
    final room = DungeonController.currentRoom;
    final kind = scene['kind'];

    if (DungeonController.isBattleKind(kind)) {
      if (room['battleWon'] == true) {
        if (room['scavengeResolved'] != true) {
          await _showScavenge();
        }
        return;
      }

      dialog.pushDialog(
        'dungeonChallengePrompt',
        interpolations: [actor['name']],
      );
      dialog.pushSelection('dungeonChallengeConfirm', ['confirm', 'cancel']);
      await dialog.execute();
      if (dialog.checkSelected('dungeonChallengeConfirm') != 'confirm') return;

      await engine.pushScene(Scenes.battle, arguments: {
        'hero': GameData.hero,
        'enemy': actor,
        'background': 'battle/scene/dungeon_night.png',
        'onBattleEnd': (bool result, int roundCount) {
          DungeonController.recordBattleResult(result);
        },
      });
      return;
    }

    if (kind == 'merchant') {
      engine.context.read<MerchantState>().show(
            actor,
            merchantType: MerchantType.none,
            enableReplenish: false,
            enableSteal: false,
          );
      return;
    }

    if (kind == 'rest') {
      final actions = scene['actions'] as List;
      final action =
          actions.firstWhere((action) => action['kind'] == 'restore');
      if (room['actionUses'][action['id']] == true) {
        dialog.pushDialog('dungeonRestUsed');
        await dialog.execute();
        return;
      }
      dialog.pushDialog('dungeonRestPrompt', npc: actor);
      dialog.pushSelection('dungeonRestConfirm', ['confirm', 'cancel']);
      await dialog.execute();
      if (dialog.checkSelected('dungeonRestConfirm') != 'confirm') return;
      if (DungeonController.useRestAction(action)) {
        gameState.updateUI();
        dialog.pushDialog('dungeonRestoreHint');
        await dialog.execute();
      }
    }
  }

  Future<void> _showScavenge() async {
    if (_scavenge != null) return;
    final room = DungeonController.currentRoom;
    if (room['battleWon'] != true || room['scavengeResolved'] == true) return;

    final candidates = DungeonController.createScavengeCandidates();
    if (candidates.isEmpty) {
      DungeonController.resolveScavenge();
      dialog.pushDialog('dungeonNoScavengeCards');
      await dialog.execute();
      return;
    }

    engine.context.read<HoverContentState>().hide();
    _scavenge = DungeonScavengeComponent(
      candidates: candidates,
      isPermanent: DungeonController.currentScene?['kind'] == 'boss',
      onSelected: (card) {
        DungeonController.resolveScavenge(selectedCard: card);
        _hideScavenge();
      },
      onSkip: () {
        DungeonController.resolveScavenge();
        _hideScavenge();
      },
      onClose: _hideScavenge,
    );
    gameState.isInteractable = false;
    _scavengeVisible.value = true;
    await camera.viewport.add(_scavenge!);
  }

  void _hideScavenge() {
    final component = _scavenge;
    if (component == null) return;
    _scavenge = null;
    component.removeFromParent();
    gameState.isInteractable = true;
    _scavengeVisible.value = false;
    engine.context.read<HoverContentState>().hide();
  }

  Future<void> _finishRunAndReturn(String outcome) async {
    final summary = DungeonController.finishRun(outcome);
    if (summary == null) return;
    await engine.popScene(clearCache: true);
    dialog.pushDialog(
      'dungeonSettlement_${summary['outcome']}',
      interpolations: [
        summary['previousLevel'],
        summary['level'],
        summary['removedDungeonCardCount'],
        summary['removedInventoryItemCount'],
      ],
    );
    await dialog.execute();
  }

  Future<void> _abandonRun() async {
    if (!DungeonController.canAbandon()) return;
    final confirmed = await showDialog<bool?>(
      context: engine.context,
      builder: (context) => ConfirmDialog(
        description: engine.locale('dungeonAbandonConfirm'),
      ),
    );
    if (confirmed == true) {
      await _finishRunAndReturn('abandon');
    }
  }

  Future<void> _settleBattleResult() async {
    final result = DungeonController.run['battleResult'];
    if (result == true) {
      final rewards = await DungeonController.grantCurrentRoomRewards();
      if (rewards.isNotEmpty) {
        await GameLogic.promptItems(rewards);
      }
      await _showScavenge();
    } else if (result == false) {
      await _finishRunAndReturn('failure');
    }
  }

  @override
  Future<void> onStart([dynamic arguments = const {}]) async {
    super.onStart(arguments);

    gameState.isInteractable = true;
    engine.context.read<HoverContentState>().hide();
    engine.context.read<ViewPanelState>().clearAll();
    gameState.updateLocation();
    await _showCurrentRoom();
    await _settleBattleResult();
  }

  @override
  void onEnd() {
    _hideScavenge();
    gameState.updateNpcs([]);
    super.onEnd();
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
          cultivationArguments: {
            'mode': 'none',
            'development': _development,
            'advanceTime': false,
          },
          showNpcs: true,
          showNpcNamesWithoutMeeting: true,
          onNpcInteract: _onNpcInteract,
          actions: [
            ValueListenableBuilder<bool>(
              valueListenable: _scavengeVisible,
              builder: (context, visible, _) => visible
                  ? const SizedBox.shrink()
                  : DropMenuButton(
                      onAbandonDungeon:
                          DungeonController.canAbandon() ? _abandonRun : null,
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

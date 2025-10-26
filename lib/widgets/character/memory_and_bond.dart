import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import 'bonds.dart';
import 'history.dart';

import '../../engine.dart';
import '../common.dart';
import 'edit_character_bond.dart';
import 'profile.dart';
import '../../data/game.dart';
import '../../ui.dart';
import '../ui/close_button2.dart';
import '../ui/responsive_view.dart';

class CharacterMemoryAndBond extends StatefulWidget {
  const CharacterMemoryAndBond({
    super.key,
    this.characterId,
    this.character,
    this.tabIndex = 0,
    this.mode = InformationViewMode.view,
  });

  final String? characterId;
  final dynamic character;
  final int tabIndex;
  final InformationViewMode mode;

  @override
  State<CharacterMemoryAndBond> createState() => _CharacterMemoryAndBondState();
}

class _CharacterMemoryAndBondState extends State<CharacterMemoryAndBond>
    with SingleTickerProviderStateMixin {
  bool get isEditorMode => widget.mode == InformationViewMode.edit;

  static List<Tab> tabs = [
    Tab(text: engine.locale('history')),
    Tab(text: engine.locale('bonds')),
  ];

  late TabController _tabController;
  late final dynamic _character;
  dynamic _bondsDataRaw;

  @override
  void initState() {
    super.initState();

    assert(widget.characterId != null || widget.character != null);
    if (widget.character != null) {
      _character = widget.character!;
    } else {
      _character = GameData.getCharacter(widget.characterId!);
    }
    assert(_character != null);

    _bondsDataRaw = _character['bonds'];

    _tabController = TabController(vsync: this, length: tabs.length);
    // _tabController.addListener(() {
    //   setState(() {
    //     if (_tabController.index == 0) {
    //       _title = engine.locale('information'];
    //     } else if (_tabController.index == 1) {
    //       _title = engine.locale('bonds'];
    //     } else if (_tabController.index == 1) {
    //       _title = engine.locale('history'];
    //     }
    //   });
    // });
    _tabController.index = widget.tabIndex;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    dynamic bondsData = {};
    if (_character == GameData.hero) {
      // 这里是为了反查出对方对玩家控制角色的好感度
      for (final key in _bondsDataRaw.keys) {
        final bond = {};
        final bondData = _bondsDataRaw[key];
        assert(bondData['id'] == key);
        bond['id'] = key;
        final targetCharacterData = GameData.getCharacter(bond['id']);
        assert(targetCharacterData != null);
        bond['name'] = bondData['name'];
        bond['relationships'] = bondData['relationships'];
        bond['score'] =
            targetCharacterData['bonds'][_character['id']]?['score'] ?? 0;
        bondsData[key] = bond;
      }
    } else {
      bondsData = _bondsDataRaw;
    }

    final preferredHeight =
        GameUI.profileWindowSize.y - GameUI.toolbarHeight * 2 - 10;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: tabs,
        ),
        SizedBox(
          height: isEditorMode ? preferredHeight - 50 : preferredHeight,
          child: TabBarView(
            controller: _tabController,
            children: [
              HistoryView(character: _character),
              CharacterBondsView(
                bondsData: bondsData,
                isHero: _character == GameData.hero,
                onPressed: (bondData) async {
                  if (isEditorMode) {
                    final result = await showDialog(
                      context: context,
                      builder: (context) => EditCharacterBond(
                        enableTargetEdit: false,
                        targetCharacterId: bondData['id'],
                        score: bondData['score'],
                        haveMet: bondData['haveMet'],
                      ),
                    );
                    if (result != null) {
                      final (_, score, haveMet) = result;
                      bondData['score'] = score;
                      bondData['haveMet'] = haveMet;
                      setState(() {});
                    }
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) => CharacterProfileView(
                        characterId: bondData['id'],
                        showIntimacy: false,
                        showPersonality: false,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        if (widget.mode != InformationViewMode.view)
          Row(
            children: [
              if (_tabController.index == 0)
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: fluent.Button(
                    onPressed: () async {
                      final result = await showDialog(
                        context: context,
                        builder: (context) => const EditCharacterBond(),
                      );
                      if (result == null) return;
                      final (targetId, score, haveMet) = result;
                      final target = GameData.getCharacter(targetId);
                      assert(target != null);
                      engine.hetu.invoke('Bond', namedArgs: {
                        'character': _character,
                        'target': target,
                        'score': score,
                        'haveMet': haveMet,
                      });
                      setState(() {});
                    },
                    child: Text(engine.locale('addBond')),
                  ),
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: fluent.Button(
                  onPressed: () {
                    Navigator.of(context).pop(_character['id']);
                  },
                  child: Text(engine.locale('confirm')),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class CharacterMemoryAndBondView extends StatelessWidget {
  const CharacterMemoryAndBondView({
    super.key,
    this.characterId,
    this.character,
    this.mode = InformationViewMode.view,
  }) : assert(characterId != null || character != null);

  final String? characterId;
  final dynamic character;
  final InformationViewMode mode;

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      width: GameUI.profileWindowSize.x,
      height: GameUI.profileWindowSize.y +
          ((mode == InformationViewMode.edit) ? 50 : 0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('memoryAndBond')),
          actions: [CloseButton2()],
        ),
        body: CharacterMemoryAndBond(
          characterId: characterId,
          character: character,
          mode: mode,
        ),
      ),
    );
  }
}

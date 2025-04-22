import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../bonds.dart';
import 'history.dart';

import '../../engine.dart';
import '../common.dart';
import 'edit_character_bond.dart';
import 'profile.dart';
import '../../game/data.dart';
import '../../game/ui.dart';
import '../ui/close_button2.dart';

class CharacterMemory extends StatefulWidget {
  const CharacterMemory({
    super.key,
    this.characterId,
    this.character,
    this.tabIndex = 0,
    this.mode = InformationViewMode.view,
    this.isHero = false,
  }) : assert(isHero == (mode == InformationViewMode.view));

  final String? characterId;

  final dynamic character;

  final int tabIndex;

  final InformationViewMode mode;

  final bool isHero;

  @override
  State<CharacterMemory> createState() => _CharacterMemoryState();
}

class _CharacterMemoryState extends State<CharacterMemory>
    with SingleTickerProviderStateMixin {
  bool get isEditorMode => widget.mode == InformationViewMode.edit;

  final _tabs = <Tab>[
    Tab(text: engine.locale('history')),
    Tab(text: engine.locale('bonds')),
  ];

  late TabController _tabController;

  // String _title = engine.locale('information'];

  late final dynamic _character;

  dynamic _bondsData;

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

    _bondsData = _character['bonds'];

    if (widget.isHero) {
      final data = {};
      for (final key in _bondsData.keys) {
        final bond = {};
        final bondData = _bondsData[key];
        assert(bondData['id'] == key);
        bond['id'] = key;
        final targetCharacterData = GameData.getCharacter(bond['id']);
        assert(targetCharacterData != null);
        final heroId = engine.hetu.invoke('getHeroId');
        bond['name'] = bondData['name'];
        bond['relationship'] = bondData['relationship'];
        bond['score'] = targetCharacterData['bonds'][heroId]?['score'];
        data[key] = bond;
      }
      _bondsData = data;
    }

    _tabController = TabController(vsync: this, length: _tabs.length);
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
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: _tabs,
        ),
        SizedBox(
          height: GameUI.profileWindowSize.y - 140,
          child: TabBarView(
            controller: _tabController,
            children: [
              HistoryView(character: _character),
              CharacterBondsView(
                bondsData: _bondsData,
                isHero: widget.isHero,
                onPressed: (bondData) {
                  if (isEditorMode) {
                    showDialog(
                      context: context,
                      builder: (context) => EditCharacterBond(
                        enableTargetEdit: false,
                        targetCharacterId: bondData['id'],
                        score: bondData['score'],
                        haveMet: bondData['haveMet'],
                      ),
                    ).then((value) {
                      if (value != null) {
                        final (_, score, haveMet) = value;
                        bondData['score'] = score;
                        bondData['haveMet'] = haveMet;
                        setState(() {});
                      }
                    });
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) => CharacterProfileView(
                        characterId: bondData['id'],
                        showIntimacy: false,
                        showPosition: false,
                        showRelationships: false,
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
                  child: fluent.FilledButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const EditCharacterBond(),
                      ).then((value) {
                        if (value != null) {
                          final (targetId, score, haveMet) = value;
                          final target = GameData.getCharacter(targetId);
                          assert(target != null);
                          engine.hetu.invoke('Bond', namedArgs: {
                            'character': _character,
                            'target': target,
                            'score': score,
                            'haveMet': haveMet,
                          });
                          setState(() {});
                        }
                      });
                    },
                    child: Text(engine.locale('addBond')),
                  ),
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: fluent.FilledButton(
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

class CharacterMemoryView extends StatelessWidget {
  const CharacterMemoryView({
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
      alignment: AlignmentDirectional.center,
      backgroundColor: GameUI.backgroundColor2,
      width: GameUI.profileWindowSize.x,
      height: GameUI.profileWindowSize.y +
          ((mode == InformationViewMode.edit) ? 50 : 0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('memory')),
          actions: [CloseButton2()],
        ),
        body: CharacterMemory(
          characterId: characterId,
          character: character,
          mode: mode,
        ),
      ),
    );
  }
}

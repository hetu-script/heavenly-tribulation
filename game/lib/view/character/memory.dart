import 'package:flutter/material.dart';

import 'relationship/bonds.dart';
import 'relationship/history.dart';
import 'package:samsara/ui/responsive_window.dart';
import 'package:samsara/ui/close_button.dart';

import '../../engine.dart';
import '../common.dart';
import 'edit_character_bond.dart';
import 'profile.dart';

class MemoryView extends StatefulWidget {
  const MemoryView({
    super.key,
    this.characterId,
    this.characterData,
    this.tabIndex = 0,
    this.mode = ViewPanelMode.view,
    this.isHero = false,
  }) : assert(isHero == (mode == ViewPanelMode.view));

  final String? characterId;

  final dynamic characterData;

  final int tabIndex;

  final ViewPanelMode mode;

  final bool isHero;

  @override
  State<MemoryView> createState() => _MemoryViewState();
}

class _MemoryViewState extends State<MemoryView>
    with SingleTickerProviderStateMixin {
  bool get isEditorMode =>
      widget.mode == ViewPanelMode.edit || widget.mode == ViewPanelMode.create;

  static final List<Tab> _tabs = <Tab>[
    Tab(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(Icons.sync_alt),
          ),
          Text(engine.locale('bonds')),
        ],
      ),
    ),
    Tab(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(Icons.history),
          ),
          Text(engine.locale('history')),
        ],
      ),
    ),
  ];

  late TabController _tabController;

  // String _title = engine.locale('information'];

  late final dynamic _characterData;

  dynamic _bondsData;

  @override
  void initState() {
    super.initState();

    if (widget.characterData != null) {
      _characterData = widget.characterData!;
    } else {
      final charId = widget.characterId ??
          ModalRoute.of(context)!.settings.arguments as String;
      _characterData =
          engine.hetu.invoke('getCharacterById', positionalArgs: [charId]);
    }

    _bondsData = _characterData['bonds'];

    if (widget.isHero) {
      final data = {};
      for (final key in _bondsData.keys) {
        final bond = {};
        final bondData = _bondsData[key];
        assert(bondData['id'] == key);
        bond['id'] = key;
        final targetCharacterData = engine.hetu
            .invoke('getCharacterById', positionalArgs: [bond['id']]);
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
    return ResponsiveWindow(
      alignment: AlignmentDirectional.center,
      size: Size(600.0, widget.mode != ViewPanelMode.view ? 450.0 : 400.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            engine.locale('memory'),
          ),
          actions: const [CloseButton2()],
          bottom: TabBar(
            controller: _tabController,
            tabs: _tabs,
            onTap: (value) {
              setState(() {
                // _showAddBondButton = value == 0;
              });
            },
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
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
                          builder: (context) => ProfileView(
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
                  CharacterHistoryView(
                    characterData: _characterData,
                  ),
                ],
              ),
            ),
            if (widget.mode != ViewPanelMode.view)
              Row(
                children: [
                  if (_tabController.index == 0)
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const EditCharacterBond(),
                          ).then((value) {
                            if (value != null) {
                              final (targetId, score, haveMet) = value;
                              final target = engine.hetu.invoke(
                                  'getCharacterById',
                                  positionalArgs: [targetId]);
                              assert(target != null);
                              engine.hetu.invoke('Bond', namedArgs: {
                                'character': _characterData,
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
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(_characterData['id']);
                      },
                      child: Text(engine.locale('confirm')),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

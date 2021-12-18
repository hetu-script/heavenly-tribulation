import 'dart:math';

import 'package:flutter/material.dart';

import '../../../engine/game.dart';
import '../../../shared/localization.dart';

class CharacterEditor extends StatefulWidget {
  const CharacterEditor(
      {Key? key,
      required this.game,
      required this.data,
      required this.onClosed})
      : super(key: key);

  final SamsaraGame game;

  final Map<String, dynamic> data;

  final void Function(Map<String, dynamic>? data) onClosed;

  @override
  _CharacterEditorState createState() => _CharacterEditorState();
}

class _CharacterEditorState extends State<CharacterEditor> {
  SamsaraGame get game => widget.game;

  GameLocalization get locale => widget.game.locale;

  Map<String, dynamic> get data => widget.data;

  static const _characterFields = [
    'characterId',
    'characterName',
    'characterAvatar',
    'characterOrganization',
    'characterRankInOrganization',
    'characterSuperiorInOrganization',
    'characterLoyaltyInOrganization',
    'characterAllegianceTo',
    'characterAllegiance',
    'characterFame',
    'characterInfamy',
    'characterLooks',
    'characterLife',
    'characterCurrentLife',
    'characterSpirit',
    'characterCurrentSpirit',
    'characterStamina',
    'characterCurrentStamina',
    'characterStrength',
    'characterDexterity',
    'characterPerception',
    'characterIntelligence',
    'characterMemory',
    'characterWaterSpiritRoot',
    'characterWoodSpiritRoot',
    'characterEarthSpiritRoot',
    'characterMetalSpiritRoot',
    'characterFireSpiritRoot',
  ];

  final _fields = <Widget>[];

  final _fieldControllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();

    _fieldControllers.addAll(
      Map.fromEntries(
        _characterFields.map(
          (field) => MapEntry(
            field,
            TextEditingController(text: data[field]),
          ),
        ),
      ),
    );

    _fields.addAll(_characterFields.map((field) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SizedBox(
          width: 400,
          child: TextFormField(
            controller: _fieldControllers[field],
            decoration: InputDecoration(
              border: const UnderlineInputBorder(),
              labelText: locale[field],
            ),
          ),
        ),
      );
    }));
  }

  void _randomize() {
    final isFemale = Random().nextInt(10) % 2 == 0;
    final List<dynamic> name =
        game.hetu.invoke('getRandomNames', namedArgs: {'isFemale': isFemale});
    setState(() {
      _fieldControllers['characterName']!.text = name.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(locale['characterEditor']),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.onClosed(null);
          },
          tooltip: locale['goBack'],
        ),
      ),
      body: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                onPressed: () {
                  setState(() {
                    widget.onClosed(data);
                  });
                },
                icon: const Icon(Icons.save),
                tooltip: locale['save'],
              ),
              IconButton(
                onPressed: _randomize,
                icon: const Icon(Icons.shuffle),
                tooltip: locale['random'],
              ),
              IconButton(
                onPressed: () {
                  setState(() {});
                },
                icon: const Icon(Icons.undo),
                tooltip: locale['reload'],
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                shrinkWrap: true,
                children: <Widget>[
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Wrap(
                        spacing: 10.0, // gap between adjacent chips
                        runSpacing: 5.0, // gap between lines
                        children: _fields,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

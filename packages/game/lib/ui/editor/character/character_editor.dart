import 'dart:math';

import 'package:flutter/material.dart';

import '../../../engine/game.dart';
import '../../../shared/localization.dart';
import '../../shared/avatar.dart';

class CharacterEditor extends StatefulWidget {
  const CharacterEditor(
      {Key? key,
      required this.game,
      required this.data,
      required this.onClosed,
      required this.maleAvatarCount,
      required this.femaleAvatarCount})
      : super(key: key);

  final SamsaraGame game;

  final Map<String, dynamic> data;

  final void Function(Map<String, dynamic>? data) onClosed;

  final int maleAvatarCount;

  final int femaleAvatarCount;

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

  Widget _textFormField(String field, {void Function()? shuffle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SizedBox(
        width: 400,
        child: TextFormField(
          controller: _fieldControllers[field],
          decoration: InputDecoration(
            border: const UnderlineInputBorder(),
            labelText: locale[field],
            suffixIcon: shuffle != null
                ? IconButton(
                    icon: const Icon(Icons.shuffle),
                    onPressed: shuffle,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    if (data['characterIsFemale'] is! bool) {
      data['characterIsFemale'] = false;
    }

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

    _fields.addAll(
      _characterFields.map(
        (field) {
          switch (field) {
            case 'characterName':
              return _textFormField(field, shuffle: () {
                setState(() {
                  _randomizeName();
                });
              });
            default:
              return _textFormField(field);
          }
        },
      ),
    );
  }

  void _randomizeAvatar() {
    final isFemale = data['characterIsFemale'];
    if (!isFemale) {
      final index = Random().nextInt(widget.maleAvatarCount);
      data['characterAvatar'] = 'avatar/male/$index.jpg';
    } else {
      final index = Random().nextInt(widget.femaleAvatarCount);
      data['characterAvatar'] = 'avatar/female/$index.jpg';
    }
  }

  void _randomizeName() {
    final List<dynamic> name = game.hetu.invoke('getRandomNames',
        namedArgs: {'isFemale': data['characterIsFemale']});
    _fieldControllers['characterName']!.text = name.first;
  }

  void _randomizeSex() {
    data['characterIsFemale'] = Random().nextInt(10) % 2 == 0;
  }

  void _randomize() {
    _randomizeAvatar();
    _randomizeSex();
    _randomizeName();
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
                onPressed: () {
                  setState(() {
                    _randomize();
                  });
                },
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
                  Container(
                    color: Colors.amber,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Avatar(
                          avatarAssetKey: data['characterAvatar'] != null
                              ? 'assets/images${data['characterAvatar']}'
                              : null,
                          size: 100,
                          radius: 50,
                        ),
                        Positioned(
                          top: 95.0,
                          left: MediaQuery.of(context).size.width / 2 + 55,
                          child: IconButton(
                            icon: const Icon(Icons.shuffle),
                            onPressed: () {
                              setState(() {
                                _randomizeAvatar();
                              });
                            },
                          ),
                        ),
                        Positioned(
                          top: 95.0,
                          left: MediaQuery.of(context).size.width / 2 - 55,
                          child: IconButton(
                            icon: data['characterIsFemale']
                                ? const Icon(Icons.female)
                                : const Icon(Icons.male),
                            onPressed: () {
                              setState(() {
                                _randomizeSex();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
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

import 'dart:math';

// import 'package:change_case/change_case.dart';
import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';

import '../../../global.dart';
import '../../shared/avatar.dart';
import '../../shared/bordered_icon_button.dart';

const kAvatarEditButtonSize = 16.0;

class CharacterEditor extends StatefulWidget {
  const CharacterEditor(
      {super.key,
      required this.data,
      required this.onClosed,
      required this.maleAvatarCount,
      required this.femaleAvatarCount});

  final Map<String, dynamic> data;

  final void Function(bool saved) onClosed;

  final int maleAvatarCount;

  final int femaleAvatarCount;

  @override
  State<CharacterEditor> createState() => _CharacterEditorState();
}

class _CharacterEditorState extends State<CharacterEditor>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  GameLocalization get locale => engine.locale;

  Map<String, dynamic> get data => widget.data;

  static const _characterFields = {
    'characterId',
    'characterName',
    'characterOrganizationIndex',
    'characterSuperiorCharacterIndexInOrganization',
    'characterRankInOrganization',
    'characterLoyaltyInOrganization',
    'characterAllegianceToCharacterIndex',
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
  };

  static const _numFields = {
    'characterRankInOrganization',
    'characterLoyaltyInOrganization',
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
  };

  final _fieldTextFields = <Widget>[];

  final _fieldControllers = <String, TextEditingController>{};

  Widget _textFormField(String field, {VoidCallback? shuffle}) {
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

    data['characterIsFemale'] ??= false;
    data['characterAvatar'] ??= 'avatar/male/1.jpg';

    _fieldControllers.addAll(
      Map.fromEntries(
        _characterFields.map((field) {
          // remove the 'character' prefix of the locale string
          // final key = field.substring(9).toLowerFirstCase();
          final fieldData = data[field];
          final fieldString = fieldData == null ? '' : fieldData.toString();
          return MapEntry(
            field,
            TextEditingController(text: fieldString),
          );
        }),
      ),
    );

    _fieldTextFields.addAll(
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
    final List<dynamic> names = engine.invoke('getCharacter',
        positionalArgs: [1],
        namedArgs: {'isFemale': data['characterIsFemale']});
    data['characterName'] = names.first;
    _fieldControllers['characterName']!.text = names.first;
  }

  void _randomizeSex() {
    data['characterIsFemale'] = Random().nextInt(2) == 0;
  }

  void _randomize() {
    _randomizeSex();
    _randomizeAvatar();
    _randomizeName();
  }

  void _save() {
    for (final field in _characterFields) {
      final controller = _fieldControllers[field]!;
      if (field == 'characterIsFemale') {
        data[field] = controller.text == locale['female'] ? true : false;
      } else if (_numFields.contains(field)) {
        data[field] = num.tryParse(controller.text) ?? 0;
      } else {
        data[field] = controller.text.isEmpty ? null : controller.text;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    const kAvatarSize = 100.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(locale['characterEditor']),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              widget.onClosed(false);
            });
          },
          tooltip: locale['goBack'],
        ),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BorderedIconButton(
                onPressed: () {
                  setState(() {
                    final id = _fieldControllers['characterId']!;
                    if (id.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(locale['characterEditingMustEnterId']),
                        ),
                      );
                      return;
                    }
                    final name = _fieldControllers['characterName']!;
                    if (name.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text(locale['characterEditingMustEnterName']),
                        ),
                      );
                      return;
                    }
                    _save();
                    widget.onClosed(true);
                  });
                },
                icon: const Icon(Icons.save),
                tooltip: locale['save'],
                margin: const EdgeInsets.all(5.0),
              ),
              BorderedIconButton(
                onPressed: () {
                  setState(() {
                    _randomize();
                  });
                },
                icon: const Icon(Icons.shuffle),
                tooltip: locale['random'],
                margin: const EdgeInsets.all(5.0),
              ),
              BorderedIconButton(
                onPressed: () {
                  setState(() {});
                },
                icon: const Icon(Icons.undo),
                tooltip: locale['reload'],
                margin: const EdgeInsets.all(5.0),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                shrinkWrap: true,
                children: [
                  SizedBox(
                    height: 150.0,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Avatar(
                          avatarAssetKey: data['characterAvatar'] != null
                              ? 'assets/images/${data['characterAvatar']}'
                              : null,
                        ),
                        Positioned(
                          top: kAvatarSize - kAvatarEditButtonSize,
                          left: MediaQuery.of(context).size.width / 2 +
                              kAvatarSize / 2 -
                              kAvatarEditButtonSize,
                          child: BorderedIconButton(
                            iconSize: kAvatarEditButtonSize,
                            icon: const Icon(Icons.shuffle_rounded),
                            tooltip: locale['random'],
                            onPressed: () {
                              setState(() {
                                _randomizeAvatar();
                              });
                            },
                          ),
                        ),
                        Positioned(
                          top: kAvatarSize - kAvatarEditButtonSize,
                          left: MediaQuery.of(context).size.width / 2 -
                              kAvatarSize / 2 -
                              kAvatarEditButtonSize,
                          child: BorderedIconButton(
                            iconSize: kAvatarEditButtonSize,
                            icon: data['characterIsFemale']
                                ? const Icon(Icons.female_rounded)
                                : const Icon(Icons.male_rounded),
                            tooltip: locale['characterIsFemale'],
                            onPressed: () {
                              setState(() {
                                data['characterIsFemale'] =
                                    !data['characterIsFemale'];
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
                        children: _fieldTextFields,
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

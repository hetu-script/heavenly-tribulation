import 'package:flutter/material.dart';
import 'package:samsara/widgets/ui/label.dart';
import 'package:samsara/widgets/ui/responsive_view.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../avatar.dart';
import '../common.dart';
import 'edit_character_basics.dart';
import '../dialog/input_description.dart';
import '../ui/int_editor_field.dart';
import '../../game/common.dart';
import '../../ui.dart';
import '../../game/game.dart';
import 'edit_character_flags.dart';
import '../ui/close_button2.dart';

class CharacterProfile extends StatefulWidget {
  const CharacterProfile({
    super.key,
    this.characterId,
    this.character,
    this.mode = InformationViewMode.view,
    this.height = 400.0,
    this.showIntimacy = true,
    this.showPosition = true,
    this.showRelationships = true,
    this.showPersonality = true,
  });

  final String? characterId;
  final dynamic character;
  final InformationViewMode mode;
  final double height;
  final bool showIntimacy, showPosition, showRelationships, showPersonality;

  @override
  State<CharacterProfile> createState() => _CharacterProfileState();
}

class _CharacterProfileState extends State<CharacterProfile> {
  bool get isEditorMode => widget.mode == InformationViewMode.edit;

  dynamic _character;

  late bool isFemale;
  late String age;
  late int charisma, wisdom, luck;

  late String race;
  late String birthday, restLifespan;
  late String organizationName, title;

  late int fame, infamy;
  final Map<String, TextEditingController> attributeControllers = {};
  final Map<String, Widget> attributeWidgets = {};

  late String homeName;
  late String worldName, worldPosition, locationName;
  late String cultivationFavor, organizationFavor;

  late int rank, level;
  late List motivationIds;

  final Map<String, TextEditingController> personalityControllers = {};
  final Map<String, Widget> personalityWidgets = {};

  final _ageController = TextEditingController();

  @override
  void dispose() {
    super.dispose();

    _ageController.dispose();

    for (final ctrl in attributeControllers.values) {
      ctrl.dispose();
    }

    for (final ctrl in personalityControllers.values) {
      ctrl.dispose();
    }
  }

  @override
  void initState() {
    super.initState();

    assert(widget.characterId != null || widget.character != null);
    if (widget.character != null) {
      _character = widget.character!;
    } else if (widget.characterId != null) {
      _character = GameData.getCharacter(widget.characterId!);
    }
    assert(_character != null);

    for (final id in kAttributes) {
      final ctrl = TextEditingController();
      attributeControllers[id] = ctrl;

      final value = _character['stats'][id].toInt();
      ctrl.text = value.toString();

      final textWidget = isEditorMode
          ? IntEditField(controller: ctrl)
          : Text(value.toString());

      attributeWidgets[id] = SizedBox(
        height: 35.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${engine.locale(id)}: '),
            textWidget,
          ],
        ),
      );
    }

    void createLabel(id) {
      final ctrl = TextEditingController();
      personalityControllers[id] = ctrl;

      final value = _character['personality'][id].toInt();
      ctrl.text = value.toString();

      final textWidget = isEditorMode
          ? IntEditField(controller: ctrl, allowNegative: true)
          : Text(value.toString());

      personalityWidgets[id] = Container(
        height: 35.0,
        width: 125.0,
        padding: const EdgeInsets.only(left: 5.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
                '${value > 0 ? engine.locale(id) : engine.locale(kOppositePersonalities[id])}: '),
            textWidget,
          ],
        ),
      );
    }

    for (final id in kPersonalities) {
      createLabel(id);
    }

    updateData();
  }

  void updateData() {
    final none = engine.locale('none');

    age = engine.hetu
        .invoke('getCharacterAge', positionalArgs: [_character]).toString();

    _ageController.text = age;

    isFemale = _character['isFemale'] == true;

    final raceId = _character['race'];
    race = engine.locale(raceId);

    final organizationId = _character['organizationId'];
    // 这里有可能为 null
    final organization = GameData.game['organizations'][organizationId];
    organizationName = organization != null ? organization['name'] : none;

    final titleId = _character['titleId'];
    title = titleId != null ? engine.locale(titleId) : none;

    fame = _character['fame'];
    infamy = _character['infamy'];

    // final father =
    //     getNameFromId(_characterData['relationships']['fatherId'], 'none');
    // final mother =
    //     getNameFromId(_characterData['relationships']['motherId'], 'none');
    // final spouse =
    //     getNameFromId(_characterData['relationships']['spouseId'], 'none');
    // final siblings =
    //     getNamesFromIds(_characterData['relationships']['siblingIds'], 'none')
    //         .map((e) => Label(e));
    // final childs =
    //     getNamesFromIds(_characterData['relationships']['childrenIds'], 'none')
    //         .map((e) => Label(e));
    // final masterId = engine.hetu
    //     .invoke('getCharacterMasterId', positionalArgs: [_characterData]);
    // final masterName = getNameFromId(masterId, 'none');

    birthday = engine.hetu
        .invoke('getCharacterBirthDayString', positionalArgs: [_character]);
    // final birthLocationId = getNameFromId(_characterData['birthLocationId']);
    restLifespan = engine.hetu
        .invoke('getCharacterRestLifespanString', positionalArgs: [_character]);

    cultivationFavor = engine.locale(_character['cultivationFavor']);
    organizationFavor = engine.locale(_character['organizationFavor']);

    final homeId = _character['homeLocationId'];
    final homeLocation = GameData.game['locations'][homeId];
    homeName = homeLocation != null ? homeLocation['name'] : none;

    final locationId = _character['locationId'];
    final location = GameData.game['locations'][locationId];
    locationName = location != null ? location['name'] : none;

    final worldId = _character['worldId'];
    worldName = worldId != null ? GameData.universe[worldId]['name'] : none;

    final worldPositionX = _character['worldPosition']?['left'];
    final worldPositionY = _character['worldPosition']?['top'];
    if (worldPositionX != null && worldPositionY != null) {
      worldPosition = '[$worldPositionX, $worldPositionY]';
    } else {
      worldPosition = '';
    }

    rank = _character['rank'];
    level = _character['level'];

    motivationIds = _character['motivations'];

    for (final id in kAttributes) {
      final value = _character['stats'][id].toInt();
      attributeControllers[id]!.text = value.toString();
    }

    for (final id in kPersonalities) {
      int value = _character['personality'][id].toInt();
      personalityControllers[id]!.text = value.toString();
    }
  }

  void _saveData() {
    _character['isFemale'] = (isFemale == true) ? true : false;

    final newAge = int.tryParse(_ageController.text);
    if (newAge != null) {
      final birthTimestamp =
          engine.hetu.invoke('ageToBirthTimestamp', positionalArgs: [newAge]);
      _character['birthTimestamp'] = birthTimestamp;
    }

    for (final attr in kAttributes) {
      final newValue = int.tryParse(attributeControllers[attr]!.text);
      if (newValue != null) _character[attr] = newValue;
    }

    engine.hetu.invoke('characterCalculateStats', positionalArgs: [_character]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          height: widget.height,
          child: SingleChildScrollView(
            child: ListView(
              shrinkWrap: true,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 15.0, top: 10.0),
                      child: Avatar(
                        name: _character['name'],
                        size: const Size(120.0, 120.0),
                        nameAlignment: AvatarNameAlignment.bottom,
                        image:
                            AssetImage('assets/images/${_character['icon']}'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 5.0),
                      child: Text(_character['description']),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(left: 5.0),
                            width: 125.0,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 35.0,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      isEditorMode
                                          ? Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                    '${engine.locale('isFemale')}:'),
                                                Container(
                                                  width: 55,
                                                  height: 30,
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 10.0),
                                                  child: FittedBox(
                                                    fit: BoxFit.fill,
                                                    child: Switch(
                                                      value: isFemale,
                                                      activeColor: Colors.white,
                                                      onChanged: (bool value) {
                                                        setState(() {
                                                          isFemale = value;
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              '${engine.locale('gender')}: ${isFemale ? engine.locale('female') : engine.locale('male')}'),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 35.0,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${engine.locale('age')}: '),
                                      isEditorMode
                                          ? IntEditField(
                                              controller: _ageController)
                                          : Text(age),
                                      Text(engine.locale('ageYear')),
                                    ],
                                  ),
                                ),
                                ...kNonBattleAttributes
                                    .map((attrId) => attributeWidgets[attrId]!),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 5.0),
                            width: 125.0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: kBattleAttributes
                                  .map((attrId) => attributeWidgets[attrId]!)
                                  .toList(),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 5.0, top: 7.0),
                            width: 125.0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  alignment: Alignment.centerLeft,
                                  height: 35.0,
                                  child: Text(
                                      '${engine.locale('cultivationRank')}: ${engine.locale('cultivationRank_$rank')}'),
                                ),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  height: 35.0,
                                  child: Text(
                                      '${engine.locale('cultivationLevel')}: $level'),
                                ),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  height: 35.0,
                                  child:
                                      Text('${engine.locale('race')}: $race'),
                                ),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  height: 35.0,
                                  child: Text(
                                      '${engine.locale('organization')}: $organizationName'),
                                ),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  height: 35.0,
                                  child: Text(
                                      '${engine.locale('jobTitle')}: $title'),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 5.0, top: 7.0),
                            width: 160.0,
                            child: Column(
                              children: [
                                Container(
                                  alignment: Alignment.centerLeft,
                                  height: 35.0,
                                  child:
                                      Text('${engine.locale('fame')}: $fame'),
                                ),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  height: 35.0,
                                  child: Text(
                                      '${engine.locale('infamy')}: $infamy'),
                                ),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  height: 35.0,
                                  child: Text(
                                      '${engine.locale('home')}: $homeName'),
                                ),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  height: 35.0,
                                  child: Text(
                                      '${engine.locale('birthday')}: $birthday'),
                                ),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  height: 35.0,
                                  child: Text(
                                      '${engine.locale('restLifespan')}: $restLifespan'),
                                ),
                              ],
                            ),
                          ),
                          if (widget.mode == InformationViewMode.edit ||
                              widget.showIntimacy)
                            Container(
                              padding: const EdgeInsets.only(top: 7.0),
                              width: 160.0,
                              child: Column(
                                children: [
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    height: 35.0,
                                    child: Text(
                                      '${engine.locale('charismaFavor')}: ${_character['charismaFavor'].truncate()}',
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    height: 35.0,
                                    child: Text(
                                      '${engine.locale('cultivationFavor')}: $cultivationFavor',
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    height: 35.0,
                                    child: Text(
                                      '${engine.locale('organizationFavor')}: $organizationFavor',
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    height: 35.0,
                                    child: Text(
                                        '${engine.locale('world')}: $worldName$worldPosition'),
                                  ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    height: 35.0,
                                    child: Text(
                                        '${engine.locale('location')}: $locationName'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (widget.mode == InformationViewMode.edit ||
                          widget.showPersonality) ...[
                        const Divider(),
                        // Text('---${engine.locale('personality')}---'),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ...kWorldViews.map((id) => personalityWidgets[id]!),
                            LabelsWrap(
                              '${engine.locale('motivation')}:',
                              minWidth: 125.0,
                              children: motivationIds.isNotEmpty
                                  ? motivationIds
                                      .map((e) => Label(engine.locale(e)))
                                      .toList()
                                  : [Text(engine.locale('none'))],
                            ),
                          ],
                        ),
                        Wrap(
                          children: kPersonalitiesWithoutWorldViews
                              .map((id) => personalityWidgets[id]!)
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.mode != InformationViewMode.view)
          Row(
            children: [
              if (widget.mode == InformationViewMode.edit) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 10.0, left: 10.0),
                  child: fluent.FilledButton(
                    onPressed: () {
                      setState(() {
                        _character = engine.hetu.invoke('Character');
                        updateData();
                      });
                    },
                    child: Text(engine.locale('randomize')),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0, left: 10.0),
                  child: fluent.FilledButton(
                    onPressed: () async {
                      final value = await showDialog(
                        context: context,
                        builder: (context) => EditCharacterBasics(
                          id: _character['id'],
                          surName: _character['surName'],
                          shortName: _character['shortName'],
                          isFemale: _character['isFemale'],
                          race: _character['race'],
                          icon: _character['icon'],
                          illustration: _character['illustration'],
                          skin: _character['skin'],
                        ),
                      );
                      if (value == null) return;
                      final (
                        id,
                        surName,
                        shortName,
                        isFemale,
                        race,
                        icon,
                        illustration,
                        skin,
                      ) = value;
                      _character['surName'] = surName;
                      assert(shortName != null && shortName.isNotEmpty);
                      _character['shortName'] = shortName;
                      _character['name'] = (surName ?? '') + shortName;
                      _character['isFemale'] = isFemale;
                      _character['race'] = race;
                      _character['skin'] = skin;
                      _character['icon'] = icon;
                      _character['illustration'] = illustration;
                      if (id != null && id != _character['id']) {
                        final originId = _character['id'];

                        GameData.game['characters'].remove(_character['id']);
                        _character['id'] = id;
                        GameData.game['characters'][id] = _character;

                        if (GameData.game['heroId'] == originId) {
                          engine.hetu.invoke('setHero', positionalArgs: [id]);
                        }
                      }
                      setState(() {});
                    },
                    child: Text(
                      engine.locale('editIdAndImage'),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0, left: 10.0),
                  child: fluent.FilledButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) => InputDescriptionDialog(
                                description: _character['description'],
                              )).then((value) {
                        if (value == null) return;
                        setState(() {
                          _character['description'] = value;
                        });
                      });
                    },
                    child: Text(engine.locale('editDescription')),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0, left: 10.0),
                  child: fluent.FilledButton(
                    onPressed: () async {
                      final value = await showDialog<Map<String, bool>>(
                        context: context,
                        builder: (context) =>
                            EditCharacterFlags(character: _character),
                      );
                      if (value != null) {
                        for (final key in value.keys) {
                          _character[key] = value[key];
                        }
                      }
                    },
                    child: Text(engine.locale('editFlags')),
                  ),
                ),
              ],
              const Spacer(),
              if (widget.mode != InformationViewMode.view)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0, right: 10.0),
                  child: fluent.FilledButton(
                    onPressed: () {
                      switch (widget.mode) {
                        case InformationViewMode.select:
                          Navigator.of(context).pop(_character['id']);
                        case InformationViewMode.edit:
                          _saveData();
                          Navigator.of(context).pop(true);
                        default:
                      }
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

class CharacterProfileView extends StatelessWidget {
  const CharacterProfileView({
    super.key,
    this.characterId,
    this.character,
    this.mode = InformationViewMode.view,
    this.height,
    this.showIntimacy = false,
    this.showPosition = false,
    this.showRelationships = false,
    this.showPersonality = false,
  });

  final String? characterId;
  final dynamic character;
  final InformationViewMode mode;
  final double? height;
  final bool showIntimacy, showPosition, showRelationships, showPersonality;

  @override
  Widget build(BuildContext context) {
    double? h = height;
    if (h == null) {
      if (mode == InformationViewMode.edit) {
        h = 700.0;
      } else {
        h = showPersonality ? 600.0 : 450.0;
      }
    }
    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.center,
      width: 800.0,
      height: h,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('information')),
          actions: [CloseButton2()],
        ),
        body: Column(
          children: [
            CharacterProfile(
              characterId: characterId,
              character: character,
              mode: mode,
              height: h - 100.0,
              showIntimacy: showIntimacy,
              showPosition: showPosition,
              showRelationships: showRelationships,
              showPersonality: showPersonality,
            ),
          ],
        ),
      ),
    );
  }
}

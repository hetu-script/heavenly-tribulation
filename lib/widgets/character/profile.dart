import 'package:flutter/material.dart';
import 'package:samsara/ui/label.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:samsara/ui/close_button2.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../avatar.dart';
import '../common.dart';
import 'edit_character_basics.dart';
import '../dialog/input_description.dart';
import '../ui/int_editor_field.dart';
import '../../common.dart';
import '../../game/ui.dart';
import '../../game/data.dart';
import 'edit_character_flags.dart';

class CharacterProfile extends StatefulWidget {
  const CharacterProfile({
    super.key,
    this.characterId,
    this.characterData,
    this.mode = InformationViewMode.view,
    this.height = 400.0,
    this.showIntimacy = true,
    this.showPosition = true,
    this.showRelationships = true,
    this.showPersonality = true,
  });

  final String? characterId;
  final dynamic characterData;
  final InformationViewMode mode;
  final double height;
  final bool showIntimacy, showPosition, showRelationships, showPersonality;

  @override
  State<CharacterProfile> createState() => _CharacterProfileState();
}

class _CharacterProfileState extends State<CharacterProfile> {
  bool get isEditorMode => widget.mode == InformationViewMode.edit;

  dynamic _characterData;

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
  late String worldId, worldPosition, locationName;
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

    assert(widget.characterId != null || widget.characterData != null);
    if (widget.characterData != null) {
      _characterData = widget.characterData!;
    } else if (widget.characterId != null) {
      _characterData = GameData.getCharacter(widget.characterId!);
    }
    assert(_characterData != null);

    for (final id in kAttributes) {
      final ctrl = TextEditingController();
      attributeControllers[id] = ctrl;

      final value = _characterData['stats'][id].toInt();
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

      final value = _characterData['personality'][id].toInt();
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

    for (final id in kWorldViews) {
      createLabel(id);
    }

    for (final id in kPersonalities) {
      createLabel(id);
    }

    updateData();
  }

  void updateData() {
    final none = engine.locale('none');

    age = engine.hetu
        .invoke('getCharacterAge', positionalArgs: [_characterData]).toString();

    _ageController.text = age;

    isFemale = _characterData['isFemale'] == true;

    final raceId = _characterData['race'];
    race = engine.locale(raceId);

    final organizationId = _characterData['organizationId'];
    final organization = GameData.gameData['organizations'][organizationId];
    organizationName = organization != null ? organization['name'] : none;

    title = _characterData['titleId'] ?? none;

    fame = _characterData['fame'];
    infamy = _characterData['infamy'];

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
        .invoke('getCharacterBirthDayString', positionalArgs: [_characterData]);
    // final birthLocationId = getNameFromId(_characterData['birthLocationId']);
    restLifespan = engine.hetu.invoke('getCharacterRestLifespanString',
        positionalArgs: [_characterData]);

    cultivationFavor = engine.locale(_characterData['cultivationFavor']);
    organizationFavor = engine.locale(_characterData['organizationFavor']);

    final homeId = _characterData['homeLocationId'];
    final homeLocation = GameData.gameData['locations'][homeId];
    homeName = homeLocation != null ? homeLocation['name'] : none;

    final locationId = _characterData['locationId'];
    final location = GameData.gameData['locations'][locationId];
    locationName = location != null ? location['name'] : none;

    worldId = _characterData['worldId'] ?? none;
    final worldPositionX = _characterData['worldPosition']?['left'];
    final worldPositionY = _characterData['worldPosition']?['top'];
    if (worldPositionX != null && worldPositionY != null) {
      worldPosition = '$worldPositionX, $worldPositionY';
    } else {
      worldPosition = none;
    }

    rank = _characterData['rank'];
    level = _characterData['level'];

    motivationIds = _characterData['motivations'];

    for (final id in kAttributes) {
      final value = _characterData['stats'][id].toInt();
      attributeControllers[id]!.text = value.toString();
    }

    for (final id in kPersonalities) {
      int value = _characterData['personality'][id].toInt();
      personalityControllers[id]!.text = value.toString();
    }
  }

  void _saveData() {
    _characterData['isFemale'] = (isFemale == true) ? true : false;

    final newAge = int.tryParse(_ageController.text);
    if (newAge != null) {
      final birthTimestamp =
          engine.hetu.invoke('ageToBirthTimestamp', positionalArgs: [newAge]);
      _characterData['birthTimestamp'] = birthTimestamp;
    }

    for (final attr in kAttributes) {
      final newValue = int.tryParse(attributeControllers[attr]!.text);
      if (newValue != null) _characterData[attr] = newValue;
    }

    engine.hetu
        .invoke('characterCalculateStats', positionalArgs: [_characterData]);
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
                        name: _characterData['name'],
                        size: const Size(120.0, 120.0),
                        nameAlignment: AvatarNameAlignment.bottom,
                        image: AssetImage(
                            'assets/images/${_characterData['icon']}'),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 120.0,
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Text(_characterData['description']),
                      ),
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
                            width: 160.0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                              padding:
                                  const EdgeInsets.only(left: 5.0, top: 7.0),
                              width: 140.0,
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
                                      '${engine.locale('charismaFavor')}: ${_characterData['charismaFavor'].truncate()}',
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
                                ],
                              ),
                            ),
                          if (widget.mode == InformationViewMode.edit ||
                              widget.showPosition)
                            Container(
                              padding:
                                  const EdgeInsets.only(left: 5.0, top: 7.0),
                              width: 200.0,
                              child: Column(
                                children: [
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
                                        '${engine.locale('world')}: $worldId'),
                                  ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    height: 35.0,
                                    child: Text(
                                        '${engine.locale('worldPosition')}: $worldPosition'),
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
                      const Divider(),
                      Wrap(
                        children: [
                          Label(
                            textAlign: TextAlign.left,
                            width: 125.0,
                            '${engine.locale('organization')}: $organizationName',
                          ),
                          Label(
                            textAlign: TextAlign.left,
                            width: 125.0,
                            '${engine.locale('title')}: $title',
                          ),
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
                      if (widget.mode == InformationViewMode.edit ||
                          widget.showRelationships) ...[
                        const Divider(),
                        // Text('---${engine.locale('relationship')}---'),
                        Wrap(
                          alignment: WrapAlignment.start,
                          children: [
                            // Label(
                            //   textAlign: TextAlign.left,
                            //   width: 125.0,
                            //   '${engine.locale('father')}: $father',
                            // ),
                            // Label(
                            //   textAlign: TextAlign.left,
                            //   width: 125.0,
                            //   '${engine.locale('mother')}: $mother',
                            // ),
                            // Label(
                            //   textAlign: TextAlign.left,
                            //   width: 125.0,
                            //   '${engine.locale('spouse')}: $spouse',
                            // ),
                            // LabelsWrap(
                            //   minWidth: 125.0,
                            //   '${engine.locale('children')}: ',
                            //   children: childs,
                            // ),
                            // LabelsWrap(
                            //   minWidth: 125.0,
                            //   '${engine.locale('siblings')}: ',
                            //   children: siblings,
                            // ),
                          ],
                        ),
                      ],
                      if (widget.mode == InformationViewMode.edit ||
                          widget.showPersonality) ...[
                        const Divider(),
                        // Text('---${engine.locale('personality')}---'),
                        Wrap(
                          children: kWorldViews
                              .map((id) => personalityWidgets[id]!)
                              .toList(),
                        ),
                        Wrap(
                          children: kPersonalities
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
        Row(
          children: [
            if (isEditorMode) ...[
              Padding(
                padding: const EdgeInsets.only(top: 10.0, left: 10.0),
                child: fluent.FilledButton(
                  onPressed: () {
                    setState(() {
                      _characterData = engine.hetu.invoke('Character');
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
                        id: _characterData['id'],
                        name: _characterData['shortName'],
                        model: _characterData['model'],
                        surName: _characterData['surName'],
                        iconPath: _characterData['icon'],
                        illustrationPath: _characterData['illustration'],
                      ),
                    );
                    if (value == null) return;
                    final (
                      id,
                      surName,
                      name,
                      isFemale,
                      race,
                      icon,
                      illustration,
                      model,
                    ) = value;
                    _characterData['surName'] = surName;
                    assert(name != null && name.isNotEmpty);
                    _characterData['shortName'] = name;
                    _characterData['name'] = (_characterData['surName'] ?? '') +
                        _characterData['shortName'];
                    _characterData['isFemale'] = isFemale;
                    _characterData['race'] = race;
                    _characterData['model'] = model;
                    _characterData['icon'] = icon;
                    _characterData['illustration'] = illustration;
                    if (id != null && id != _characterData['id']) {
                      final originId = _characterData['id'];

                      GameData.gameData['characters']
                          .remove(_characterData['id']);
                      _characterData['id'] = id;
                      GameData.gameData['characters'][id] = _characterData;

                      if (GameData.gameData['heroId'] == originId) {
                        engine.hetu.invoke('setHeroId', positionalArgs: [id]);
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
                              description: _characterData['description'],
                            )).then((value) {
                      if (value == null) return;
                      setState(() {
                        _characterData['description'] = value;
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
                          EditCharacterFlags(characterData: _characterData),
                    );
                    if (value != null) {
                      for (final key in value.keys) {
                        _characterData[key] = value[key];
                      }
                    }
                  },
                  child: Text(engine.locale('editFlags')),
                ),
              ),
              const Spacer(),
              if (widget.mode != InformationViewMode.view)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0, right: 10.0),
                  child: fluent.FilledButton(
                    onPressed: () {
                      switch (widget.mode) {
                        case InformationViewMode.select:
                          Navigator.of(context).pop(_characterData['id']);
                        case InformationViewMode.edit:
                          _saveData();
                          Navigator.of(context).pop(true);
                        // case InformationViewMode.create:
                        //   _saveData();
                        //   Navigator.of(context).pop(_characterData);
                        default:
                      }
                    },
                    child: Text(engine.locale('confirm')),
                  ),
                ),
            ],
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
    this.characterData,
    this.mode = InformationViewMode.view,
    this.height,
    this.showIntimacy = false,
    this.showPosition = false,
    this.showRelationships = false,
    this.showPersonality = false,
  });

  final String? characterId;
  final dynamic characterData;
  final InformationViewMode mode;
  final double? height;
  final bool showIntimacy, showPosition, showRelationships, showPersonality;

  @override
  Widget build(BuildContext context) {
    final h = height ?? (mode == InformationViewMode.edit ? 700.0 : 400.0);
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
              characterData: characterData,
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

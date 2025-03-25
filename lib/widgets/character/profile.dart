import 'package:flutter/material.dart';
import 'package:samsara/ui/label.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:samsara/ui/close_button2.dart';

import '../../engine.dart';
import '../avatar.dart';
import '../../util.dart';
import '../common.dart';
import 'edit_character_basics.dart';
import '../dialog/input_description.dart';
import '../int_editor_field.dart';
import '../../common.dart';
import '../../game/ui.dart';

class CharacterProfile extends StatefulWidget {
  const CharacterProfile({
    super.key,
    this.characterId,
    this.characterData,
    this.mode = InformationViewMode.view,
    this.height = 400.0,
    this.showIntimacy = true,
    this.showRelationships = true,
    this.showPosition = true,
    this.showPersonality = true,
    this.showDescription = true,
  });

  final String? characterId;
  final dynamic characterData;
  final InformationViewMode mode;
  final double height;
  final bool showIntimacy,
      showRelationships,
      showPosition,
      showPersonality,
      showDescription;

  @override
  State<CharacterProfile> createState() => _CharacterProfileState();
}

class _CharacterProfileState extends State<CharacterProfile> {
  bool get isEditorMode => widget.mode == InformationViewMode.edit;

  dynamic _characterData;

  late String age;

  late bool _isFemale;

  late int charisma, wisdom, luck;

  final Map<String, TextEditingController> attributeControllers = {};
  final Map<String, Widget> attributeWidgets = {};

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
      _characterData = engine.hetu
          .invoke('getCharacterById', positionalArgs: [widget.characterId]);
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

    for (final id in kPersonalities) {
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

    updateData();
  }

  void updateData() {
    age = engine.hetu
        .invoke('getCharacterAge', positionalArgs: [_characterData]).toString();

    _ageController.text = age;

    _isFemale = _characterData['isFemale'] == true;

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
    _characterData['isFemale'] = _isFemale == 'female' ? true : false;

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
        .invoke('calculateCharacterStats', positionalArgs: [_characterData]);
  }

  @override
  Widget build(BuildContext context) {
    final int fame = _characterData['fame'];
    final int infamy = _characterData['infamy'];
    // final masterId = engine.hetu
    //     .invoke('getCharacterMasterId', positionalArgs: [_characterData]);
    // final masterName = getNameFromId(masterId, 'none');
    final organizationId =
        getNameFromId(_characterData['organizationId'], 'none');
    final title = _characterData['titleId'] ?? engine.locale('none');
    final home = getNameFromId(_characterData['homeLocationId'], 'none');

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

    final birthday = engine.hetu
        .invoke('getCharacterBirthDayString', positionalArgs: [_characterData]);
    // final birthLocationId = getNameFromId(_characterData['birthLocationId']);
    final restLifespan = engine.hetu.invoke('getCharacterRestLifespanString',
        positionalArgs: [_characterData]);

    final worldId = _characterData['worldId'];

    final worldPositionX = _characterData['worldPosition']?['left'];
    final worldPositionY = _characterData['worldPosition']?['top'];
    var worldPositionString = engine.locale('unknown');
    if (worldPositionX != null && worldPositionY != null) {
      worldPositionString = '$worldPositionX, $worldPositionY';
    }
    final locationId = getNameFromId(_characterData['locationId'], 'none');
    final siteId = getNameFromId(_characterData['siteId'], 'none');
    final cultivationFavor = engine.locale(_characterData['cultivationFavor']);
    final organizationFavor =
        engine.locale(_characterData['organizationFavor']);

    final motifvationNames = _characterData['motivations'] as List;
    final motivations = motifvationNames.isNotEmpty
        ? motifvationNames.map((e) => Label(engine.locale(e))).toList()
        : [Text(engine.locale('none'))];

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
                        displayName: _characterData['name'],
                        size: const Size(120.0, 120.0),
                        nameAlignment: AvatarNameAlignment.bottom,
                        image: AssetImage(
                            'assets/images/${_characterData['icon']}'),
                      ),
                    ),
                    SizedBox(
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
                                        children: [
                                          SizedBox(
                                            width: 40,
                                            child: Text(
                                                '${engine.locale('isFemale')}: '),
                                          ),
                                          Container(
                                            width: 50,
                                            height: 30,
                                            padding: const EdgeInsets.only(
                                                left: 10.0),
                                            child: FittedBox(
                                              fit: BoxFit.fill,
                                              child: Switch(
                                                value: _isFemale,
                                                activeColor: Colors.white,
                                                onChanged: (bool value) {
                                                  setState(() {
                                                    _isFemale = value;
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        '${engine.locale('gender')}: ${_isFemale ? engine.locale('female') : engine.locale('male')}'),
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
                                    ? IntEditField(controller: _ageController)
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
                    SizedBox(
                      width: 125.0,
                      child: Column(
                        children: kBattleAttributes
                            .map((attrId) => attributeWidgets[attrId]!)
                            .toList(),
                      ),
                    ),
                    Container(
                      width: 125.0,
                      padding: const EdgeInsets.only(top: 7.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            alignment: Alignment.centerLeft,
                            height: 35.0,
                            child: Text('${engine.locale('fame')}: $fame'),
                          ),
                          Container(
                            alignment: Alignment.centerLeft,
                            height: 35.0,
                            child: Text('${engine.locale('infamy')}: $infamy'),
                          ),
                          Container(
                            alignment: Alignment.centerLeft,
                            height: 35.0,
                            child: Text(
                                '${engine.locale('organization')}: $organizationId'),
                          ),
                          Container(
                            alignment: Alignment.centerLeft,
                            height: 35.0,
                            child: Text('${engine.locale('title')}: $title'),
                          ),
                        ],
                      ),
                    ),
                    if (widget.showIntimacy)
                      Container(
                        padding: const EdgeInsets.only(top: 7.0),
                        width: 150.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
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
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.showRelationships) ...[
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
                      if (widget.showPosition) ...[
                        const Divider(),
                        Wrap(
                          children: [
                            Label(
                              textAlign: TextAlign.left,
                              '${engine.locale('home')}: $home',
                              width: 125.0,
                            ),
                            Label(
                              textAlign: TextAlign.left,
                              '${engine.locale('location')}: $locationId',
                              width: 125.0,
                            ),
                            Label(
                              textAlign: TextAlign.left,
                              '${engine.locale('site')}: $siteId',
                              width: 125.0,
                            ),
                            Label(
                              textAlign: TextAlign.left,
                              '${engine.locale('worldPosition')}: $worldPositionString',
                              width: 125.0,
                            ),
                            Label(
                              textAlign: TextAlign.left,
                              '${engine.locale('world')}: $worldId',
                              width: 125.0,
                            ),
                          ],
                        ),
                      ],
                      if (widget.showPersonality) ...[
                        const Divider(),
                        // Text('---${engine.locale('personality')}---'),
                        Wrap(
                          children: [
                            ...kPersonalities
                                .map((id) => personalityWidgets[id]!),
                            Container(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: LabelsWrap(
                                '${engine.locale('motivation')}:',
                                minWidth: 125.0,
                                children: motivations,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (widget.showDescription) ...[
                        const Divider(),
                        SizedBox(
                          width: 640.0,
                          child: Text(_characterData['description']),
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
                child: ElevatedButton(
                  onPressed: () async {
                    final value = await showDialog(
                      context: context,
                      builder: (context) => EditCharacterBasics(
                        id: _characterData['id'],
                        name: _characterData['shortName'],
                        skin: _characterData['characterSkin'],
                        surName: _characterData['surName'],
                        iconPath: _characterData['icon'],
                        illustrationPath: _characterData['illustration'],
                      ),
                    );
                    if (value == null) return;
                    final (
                      id,
                      name,
                      surName,
                      isFemale,
                      skin,
                      icon,
                      illustration,
                    ) = value;
                    _characterData['surName'] = surName;
                    assert(name != null && name.isNotEmpty);
                    _characterData['shortName'] = name;
                    _characterData['name'] = (_characterData['surName'] ?? '') +
                        _characterData['shortName'];
                    _characterData['isFemale'] = isFemale;
                    _characterData['characterSkin'] = skin;
                    _characterData['icon'] = icon;
                    _characterData['illustration'] = illustration;
                    if (id != null && id != _characterData['id']) {
                      final originId = _characterData['id'];

                      engine.hetu.invoke('removeCharacterById',
                          positionalArgs: [_characterData['id']]);
                      _characterData['id'] = id;
                      engine.hetu.invoke('addCharacter',
                          positionalArgs: [_characterData]);

                      final heroId = engine.hetu.invoke('getHeroId');
                      if (originId == heroId) {
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
                child: ElevatedButton(
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
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _characterData = engine.hetu.invoke('Character');
                      updateData();
                    });
                  },
                  child: Text(engine.locale('random')),
                ),
              ),
              const Spacer(),
              if (widget.mode != InformationViewMode.view)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0, right: 10.0),
                  child: ElevatedButton(
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
    this.showIntimacy = true,
    this.showRelationships = true,
    this.showPosition = true,
    this.showPersonality = true,
    this.showDescription = true,
  });

  final String? characterId;

  final dynamic characterData;

  final InformationViewMode mode;

  final bool showIntimacy,
      showRelationships,
      showPosition,
      showPersonality,
      showDescription;

  @override
  Widget build(BuildContext context) {
    final width = mode != InformationViewMode.view ? 700.0 : 640.0;
    final height = mode != InformationViewMode.view ? 640.0 : 400.0;
    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.center,
      width: width,
      height: height,
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
              height: height - 90.0,
              showIntimacy: showIntimacy,
              showRelationships: showRelationships,
              showPosition: showPosition,
              showPersonality: showPersonality,
              showDescription: showDescription,
            ),
          ],
        ),
      ),
    );
  }
}

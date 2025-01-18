import 'package:flutter/material.dart';
import 'package:samsara/ui/label.dart';
import 'package:samsara/ui/responsive_panel.dart';
import 'package:samsara/ui/close_button2.dart';

import '../../engine.dart';
import '../avatar.dart';
import '../../util.dart';
import '../common.dart';
import 'edit_character_id_and_avatar.dart';
import '../dialog/input_description.dart';
import '../int_editor_field.dart';

class CharacterProfile extends StatefulWidget {
  const CharacterProfile({
    super.key,
    this.characterId,
    this.characterData,
    this.mode = InformationViewMode.view,
    this.height = 300.0,
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
  bool get isEditorMode =>
      widget.mode == InformationViewMode.edit ||
      widget.mode == InformationViewMode.create;

  dynamic _characterData;

  late String age, sex;

  late int charisma,
      wisdom,
      luck,
      spirituality,
      dexterity,
      strength,
      willpower,
      perception;

  final _ageController = TextEditingController();

  final _charismaController = TextEditingController();
  final _wisdomController = TextEditingController();
  final _luckController = TextEditingController();

  final _spiritualityController = TextEditingController();
  final _dexterityController = TextEditingController();
  final _strengthController = TextEditingController();
  final _willpowerController = TextEditingController();
  final _perceptionController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.mode.index <= 2) {
      if (widget.characterData != null) {
        _characterData = widget.characterData!;
      } else if (widget.characterId != null) {
        _characterData = engine.hetu
            .invoke('getCharacterById', positionalArgs: [widget.characterId]);
      }
    } else {
      // 临时创建的数据，此时尚未加入游戏中
      _characterData = engine.hetu.invoke('Character', namedArgs: {
        'isMajorCharacter': false,
      });
    }

    updateData();
  }

  void updateData() {
    age = engine.hetu
        .invoke('getCharacterAge', positionalArgs: [_characterData]).toString();

    _ageController.text = age;

    sex = _characterData['isFemale'] ? 'female' : 'male';

    charisma = _characterData['charisma'].toInt();
    wisdom = _characterData['wisdom'].toInt();
    luck = _characterData['luck'].toInt();

    _charismaController.text = charisma.toString();
    _wisdomController.text = wisdom.toString();
    _luckController.text = luck.toString();

    spirituality = _characterData['stats']['spirituality'].toInt();
    dexterity = _characterData['stats']['dexterity'].toInt();
    strength = _characterData['stats']['strength'].toInt();
    willpower = _characterData['stats']['willpower'].toInt();
    perception = _characterData['stats']['perception'].toInt();

    _spiritualityController.text = spirituality.toString();
    _dexterityController.text = dexterity.toString();
    _strengthController.text = strength.toString();
    _willpowerController.text = willpower.toString();
    _perceptionController.text = perception.toString();
  }

  void _saveData() {
    _characterData['isFemale'] = sex == 'female' ? true : false;

    final newAge = int.tryParse(_ageController.text);
    if (newAge != null) {
      final birthTimestamp =
          engine.hetu.invoke('ageToBirthTimestamp', positionalArgs: [newAge]);
      _characterData['birthTimestamp'] = birthTimestamp;
    }

    final newCharisma = int.tryParse(_charismaController.text);
    if (newCharisma != null) _characterData['charisma'] = newCharisma;
    final newWisdom = int.tryParse(_wisdomController.text);
    if (newWisdom != null) _characterData['wisdom'] = newWisdom;
    final newLuck = int.tryParse(_luckController.text);
    if (newLuck != null) _characterData['luck'] = newLuck;

    final newSpirituality = int.tryParse(_spiritualityController.text);
    if (newSpirituality != null) {
      _characterData['spirituality'] = newSpirituality;
    }
    final newDexterity = int.tryParse(_dexterityController.text);
    if (newDexterity != null) {
      _characterData['dexterity'] = newDexterity;
    }
    final newStrength = int.tryParse(_strengthController.text);
    if (newStrength != null) {
      _characterData['strength'] = newStrength;
    }
    final newWillpower = int.tryParse(_willpowerController.text);
    if (newWillpower != null) {
      _characterData['willpower'] = newWillpower;
    }
    final newPerception = int.tryParse(_perceptionController.text);
    if (newPerception != null) {
      _characterData['perception'] = newPerception;
    }

    engine.hetu
        .invoke('updateCharacterStats', positionalArgs: [_characterData]);
  }

  @override
  Widget build(BuildContext context) {
    final fame = engine.hetu
        .invoke('getCharacterFameString', positionalArgs: [_characterData]);
    final infamy = engine.hetu
        .invoke('getCharacterInfamyString', positionalArgs: [_characterData]);
    final masterId = engine.hetu
        .invoke('getCharacterMasterId', positionalArgs: [_characterData]);
    final masterName = getNameFromId(masterId, 'none');
    final organizationId =
        getNameFromId(_characterData['organizationId'], 'none');
    final title = engine.hetu
            .invoke('getCharacterTitle', positionalArgs: [_characterData]) ??
        engine.locale('none');
    final home = getNameFromId(_characterData['homeId'], 'none');

    final father =
        getNameFromId(_characterData['relationships']['fatherId'], 'none');
    final mother =
        getNameFromId(_characterData['relationships']['motherId'], 'none');
    final spouse =
        getNameFromId(_characterData['relationships']['spouseId'], 'none');
    final siblings =
        getNamesFromIds(_characterData['relationships']['siblingIds'], 'none')
            .map((e) => Label(e));
    final childs =
        getNamesFromIds(_characterData['relationships']['childrenIds'], 'none')
            .map((e) => Label(e));

    final personality = _characterData['personality'];
    final ideal = personality['ideal'].toInt();
    final order = personality['order'].toInt();
    final good = personality['good'].toInt();
    final social = personality['social'].toInt();
    final reason = personality['reason'].toInt();
    final control = personality['control'].toInt();
    final frugal = personality['frugal'].toInt();
    final frank = personality['frank'].toInt();
    final confidence = personality['confidence'].toInt();
    final prudence = personality['prudence'].toInt();
    final empathy = personality['empathy'].toInt();
    final generosity = personality['generosity'].toInt();

    final birthday = engine.hetu
        .invoke('getCharacterBirthDayString', positionalArgs: [_characterData]);
    // final birthPlace = getNameFromId(_characterData['birthPlaceId']);
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
    final thinkingNames = _characterData['thinkings'] as List;
    final thinkings = thinkingNames.isNotEmpty
        ? thinkingNames.map((e) => Label(engine.locale(e))).toList()
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
                            'assets/images/illustration/${_characterData['icon']}'),
                      ),
                    ),
                    SizedBox(
                      width: 125.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 35.0,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${engine.locale('gender')}: '),
                                isEditorMode
                                    ? Padding(
                                        padding: EdgeInsets.only(top: 10.0),
                                        child: DropdownButton<String>(
                                          items: <String>['male', 'female']
                                              .map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(
                                                engine.locale(value),
                                                style:
                                                    TextStyle(fontSize: 16.0),
                                              ),
                                            );
                                          }).toList(),
                                          value: sex,
                                          onChanged: (value) {
                                            setState(() {
                                              sex = value!;
                                            });
                                          },
                                        ),
                                      )
                                    : Text(engine.locale(sex)),
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
                          SizedBox(
                            height: 35.0,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${engine.locale('charisma')}: '),
                                isEditorMode
                                    ? IntEditField(
                                        controller: _charismaController)
                                    : Text('$charisma'),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 35.0,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${engine.locale('wisdom')}: '),
                                isEditorMode
                                    ? IntEditField(
                                        controller: _wisdomController)
                                    : Text('$wisdom'),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 35.0,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${engine.locale('luck')}: '),
                                isEditorMode
                                    ? IntEditField(controller: _luckController)
                                    : Text('$luck'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 125.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 35.0,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${engine.locale('spirituality')}: '),
                                isEditorMode
                                    ? IntEditField(
                                        controller: _spiritualityController)
                                    : Text('$spirituality'),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 35.0,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${engine.locale('dexterity')}: '),
                                isEditorMode
                                    ? IntEditField(
                                        controller: _dexterityController)
                                    : Text('$dexterity'),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 35.0,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${engine.locale('strength')}: '),
                                isEditorMode
                                    ? IntEditField(
                                        controller: _strengthController)
                                    : Text('$strength'),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 35.0,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${engine.locale('willpower')}: '),
                                isEditorMode
                                    ? IntEditField(
                                        controller: _willpowerController)
                                    : Text('$willpower'),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 35.0,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${engine.locale('perception')}: '),
                                isEditorMode
                                    ? IntEditField(
                                        controller: _perceptionController)
                                    : Text('$perception'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.only(top: 5.0),
                      width: 125.0,
                      height: 190.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 35.0,
                            child: Text('${engine.locale('fame')}: $fame'),
                          ),
                          SizedBox(
                            height: 35.0,
                            child: Text('${engine.locale('infamy')}: $infamy'),
                          ),
                          SizedBox(
                            height: 35.0,
                            child:
                                Text('${engine.locale('master')}: $masterName'),
                          ),
                          SizedBox(
                            height: 35.0,
                            child: Text(
                                '${engine.locale('organization')}: $organizationId'),
                          ),
                          SizedBox(
                            height: 35.0,
                            child: Text('${engine.locale('title')}: $title'),
                          ),
                        ],
                      ),
                    ),
                    if (widget.showIntimacy)
                      Container(
                        padding: const EdgeInsets.only(top: 5.0),
                        width: 150.0,
                        height: 190.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 35.0,
                              child: Text(
                                '${engine.locale('charismaFavor')}: ${_characterData['charismaFavor'].truncate()}',
                              ),
                            ),
                            SizedBox(
                              height: 35.0,
                              child: Text(
                                '${engine.locale('cultivationFavor')}: $cultivationFavor',
                              ),
                            ),
                            SizedBox(
                              height: 35.0,
                              child: Text(
                                '${engine.locale('organizationFavor')}: $organizationFavor',
                              ),
                            ),
                            SizedBox(
                              height: 35.0,
                              child: Text(
                                  '${engine.locale('birthday')}: $birthday'),
                            ),
                            SizedBox(
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
                            Label(
                              textAlign: TextAlign.left,
                              width: 125.0,
                              '${engine.locale('father')}: $father',
                            ),
                            Label(
                              textAlign: TextAlign.left,
                              width: 125.0,
                              '${engine.locale('mother')}: $mother',
                            ),
                            Label(
                              textAlign: TextAlign.left,
                              width: 125.0,
                              '${engine.locale('spouse')}: $spouse',
                            ),
                            LabelsWrap(
                              minWidth: 125.0,
                              '${engine.locale('children')}: ',
                              children: childs,
                            ),
                            LabelsWrap(
                              minWidth: 125.0,
                              '${engine.locale('siblings')}: ',
                              children: siblings,
                            ),
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
                            Label(
                              textAlign: TextAlign.left,
                              ideal >= 0
                                  ? '${engine.locale('ideal')}: $ideal'
                                  : '${engine.locale('real')}: ${-ideal}',
                              width: 125.0,
                            ),
                            Label(
                              textAlign: TextAlign.left,
                              order >= 0
                                  ? '${engine.locale('order')}: $order'
                                  : '${engine.locale('chaotic')}: ${-order}',
                              width: 125.0,
                            ),
                            Label(
                              textAlign: TextAlign.left,
                              good >= 0
                                  ? '${engine.locale('good')}: $good'
                                  : '${engine.locale('evil')}: ${-good}',
                              width: 125.0,
                            ),
                            Label(
                              textAlign: TextAlign.left,
                              social >= 0
                                  ? '${engine.locale('extraversion')}: $social'
                                  : '${engine.locale('introspection')}: ${-social}',
                              width: 125.0,
                            ),
                            Label(
                              textAlign: TextAlign.left,
                              reason >= 0
                                  ? '${engine.locale('reasoning')}: $reason'
                                  : '${engine.locale('feeling')}: ${-reason}',
                              width: 125.0,
                            ),
                            Label(
                              textAlign: TextAlign.left,
                              control >= 0
                                  ? '${engine.locale('organizing')}: $control'
                                  : '${engine.locale('relaxing')}: ${-control}',
                              width: 125.0,
                            ),
                            Label(
                              textAlign: TextAlign.left,
                              frugal >= 0
                                  ? '${engine.locale('frugality')}: $frugal'
                                  : '${engine.locale('lavishness')}: ${-frugal}',
                              width: 125.0,
                            ),
                            Label(
                              textAlign: TextAlign.left,
                              frank >= 0
                                  ? '${engine.locale('frankness')}: $frank'
                                  : '${engine.locale('tactness')}: ${-frank}',
                              width: 125.0,
                            ),
                            Label(
                              textAlign: TextAlign.left,
                              confidence >= 0
                                  ? '${engine.locale('confidence')}: $confidence'
                                  : '${engine.locale('cowardness')}: ${-confidence}',
                              width: 125.0,
                            ),
                            Label(
                              textAlign: TextAlign.left,
                              prudence >= 0
                                  ? '${engine.locale('prudence')}: $prudence'
                                  : '${engine.locale('adventurousness')}: ${-prudence}',
                              width: 125.0,
                            ),
                            Label(
                              textAlign: TextAlign.left,
                              empathy >= 0
                                  ? '${engine.locale('empathy')}: $empathy'
                                  : '${engine.locale('indifference')}: ${-empathy}',
                              width: 125.0,
                            ),
                            Label(
                              textAlign: TextAlign.left,
                              generosity >= 0
                                  ? '${engine.locale('generosity')}: $generosity'
                                  : '${engine.locale('stinginess')}: ${-generosity}',
                              width: 125.0,
                            ),
                            // const Divider(
                            //   color: Colors.transparent,
                            //   height: 0.0,
                            // ),
                            LabelsWrap(
                              '${engine.locale('motivation')}:',
                              minWidth: 125.0,
                              children: motivations,
                            ),
                            LabelsWrap(
                              '${engine.locale('thinking')}:',
                              minWidth: 125.0,
                              children: thinkings,
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
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => EditCharacterIdAndAvatar(
                        id: _characterData['id'],
                        name: _characterData['shortName'],
                        skin: _characterData['characterSkin'],
                        familyName: _characterData['familyName'],
                        iconPath: _characterData['icon'],
                        illustrationPath: _characterData['illustration'],
                      ),
                    ).then(
                      (value) {
                        if (value == null) return;
                        final (
                          id,
                          name,
                          familyName,
                          skin,
                          iconPath,
                          illustrationPath,
                        ) = value;
                        _characterData['familyName'] = familyName;
                        assert(name != null && name.isNotEmpty);
                        _characterData['shortName'] = name;
                        _characterData['name'] =
                            (_characterData['familyName'] ?? '') +
                                _characterData['shortName'];
                        _characterData['characterSkin'] = skin;
                        _characterData['icon'] = iconPath;
                        _characterData['illustration'] = illustrationPath;
                        if (id != null && id != _characterData['id']) {
                          engine.hetu.invoke('removeCharacterById',
                              positionalArgs: [_characterData['id']]);
                          final heroId = engine.hetu.invoke('getHeroId');
                          final originId = _characterData['id'];
                          _characterData['id'] = id;
                          engine.hetu.invoke('addCharacter',
                              positionalArgs: [_characterData]);
                          if (originId == heroId) {
                            engine.hetu
                                .invoke('setHeroId', positionalArgs: [id]);
                          }
                        }
                        setState(() {});
                      },
                    );
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
                      _characterData =
                          engine.hetu.invoke('Character', namedArgs: {
                        'isMajorCharacter': false,
                      });
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
                        case InformationViewMode.create:
                          _saveData();
                          Navigator.of(context).pop(_characterData);
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

class CharacterProfilePanel extends StatelessWidget {
  const CharacterProfilePanel({
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
    return ResponsivePanel(
      alignment: AlignmentDirectional.center,
      width: 700,
      height: 480.0,
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
              height: 380,
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

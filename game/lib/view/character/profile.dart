import 'package:flutter/material.dart';
import 'package:samsara/ui/label.dart';
import 'package:samsara/ui/responsive_window.dart';
import 'package:samsara/ui/close_button.dart';
import 'package:flutter/services.dart';

import '../../config.dart';
import '../avatar.dart';
import '../../util.dart';
import '../common.dart';
import 'edit_character_id_and_avatar.dart';
import '../../dialog/input_description.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({
    super.key,
    this.characterId,
    this.characterData,
    this.mode = ViewPanelMode.view,
    this.showIntimacy = true,
    this.showRelationships = true,
    this.showPosition = true,
    this.showPersonality = true,
    this.showDescription = true,
  });

  final String? characterId;

  final dynamic characterData;

  final ViewPanelMode mode;

  final bool showIntimacy,
      showRelationships,
      showPosition,
      showPersonality,
      showDescription;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool get isEditorMode =>
      widget.mode == ViewPanelMode.edit || widget.mode == ViewPanelMode.create;

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
    age = engine.hetu.invoke('getEntityAge', positionalArgs: [_characterData]);

    _ageController.text = age;

    sex = _characterData['isFemale'] ? 'female' : 'male';

    charisma = _characterData['charisma'].toInt();
    wisdom = _characterData['wisdom'].toInt();
    luck = _characterData['luck'].toInt();

    _charismaController.text = charisma.toString();
    _wisdomController.text = wisdom.toString();
    _luckController.text = luck.toString();

    spirituality = _characterData['attributes']['spirituality'].toInt();
    dexterity = _characterData['attributes']['dexterity'].toInt();
    strength = _characterData['attributes']['strength'].toInt();
    willpower = _characterData['attributes']['willpower'].toInt();
    perception = _characterData['attributes']['perception'].toInt();

    _spiritualityController.text = spirituality.toString();
    _dexterityController.text = dexterity.toString();
    _strengthController.text = strength.toString();
    _willpowerController.text = willpower.toString();
    _perceptionController.text = perception.toString();
  }

  void _saveData() {
    final newAge = int.tryParse(_ageController.text);
    if (newAge != null) {
      final birthTimestamp =
          engine.hetu.invoke('ageToBirthTimestamp', positionalArgs: [newAge]);
      _characterData['birthTimestamp'] = birthTimestamp;
    }

    _characterData['isFemale'] = sex == 'female' ? true : false;

    final newCharisma = int.tryParse(_charismaController.text);
    if (newCharisma != null) _characterData['charisma'] = newCharisma;
    final newWisdom = int.tryParse(_wisdomController.text);
    if (newWisdom != null) _characterData['wisdom'] = newWisdom;
    final newLuck = int.tryParse(_luckController.text);
    if (newLuck != null) _characterData['luck'] = newLuck;
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
        .invoke('getEntityBirthDayString', positionalArgs: [_characterData]);
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

    return ResponsiveWindow(
      color: kBackgroundColor,
      alignment: AlignmentDirectional.center,
      size: Size(680.0, widget.mode != ViewPanelMode.view ? 450.0 : 400.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            engine.locale('information'),
          ),
          actions: const [CloseButton2()],
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              height: 360.0,
              child: SingleChildScrollView(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: Avatar(
                            displayName: _characterData['name'],
                            size: const Size(120.0, 120.0),
                            nameAlignment: AvatarNameAlignment.bottom,
                            image: AssetImage(
                                'assets/images/avatar/${_characterData['icon']}'),
                          ),
                        ),
                        SizedBox(
                          width: 125.0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 30.0,
                                child: Row(children: [
                                  Text('${engine.locale('gender')}: '),
                                  isEditorMode
                                      ? DropdownButton<String>(
                                          items: <String>['male', 'female']
                                              .map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(engine.locale(value)),
                                            );
                                          }).toList(),
                                          value: sex,
                                          onChanged: (value) {
                                            setState(() {
                                              sex = value!;
                                            });
                                          },
                                        )
                                      : Text(engine.locale(sex)),
                                ]),
                              ),
                              SizedBox(
                                height: 30.0,
                                child: Row(
                                  children: [
                                    Text('${engine.locale('age')}: '),
                                    isEditorMode
                                        ? Container(
                                            alignment: Alignment.topCenter,
                                            width: 40.0,
                                            height: 10.0,
                                            child: TextField(
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    4),
                                              ],
                                              keyboardType:
                                                  TextInputType.number,
                                              textAlign: TextAlign.center,
                                              controller: _ageController,
                                            ),
                                          )
                                        : Text(age),
                                    Text(engine.locale('ageYear')),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 30.0,
                                child: Row(
                                  children: [
                                    Text('${engine.locale('charisma')}: '),
                                    isEditorMode
                                        ? Container(
                                            alignment: Alignment.topCenter,
                                            width: 40.0,
                                            height: 10.0,
                                            child: TextField(
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    3),
                                              ],
                                              keyboardType:
                                                  TextInputType.number,
                                              textAlign: TextAlign.center,
                                              controller: _charismaController,
                                            ),
                                          )
                                        : Text('$charisma'),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 30.0,
                                child: Row(
                                  children: [
                                    Text('${engine.locale('wisdom')}: '),
                                    isEditorMode
                                        ? Container(
                                            alignment: Alignment.topCenter,
                                            width: 40.0,
                                            height: 10.0,
                                            child: TextField(
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    3),
                                              ],
                                              keyboardType:
                                                  TextInputType.number,
                                              textAlign: TextAlign.center,
                                              controller: _wisdomController,
                                            ),
                                          )
                                        : Text('$wisdom'),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 30.0,
                                child: Row(
                                  children: [
                                    Text('${engine.locale('luck')}: '),
                                    isEditorMode
                                        ? Container(
                                            alignment: Alignment.topCenter,
                                            width: 40.0,
                                            height: 10.0,
                                            child: TextField(
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    3),
                                              ],
                                              keyboardType:
                                                  TextInputType.number,
                                              textAlign: TextAlign.center,
                                              controller: _luckController,
                                            ),
                                          )
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
                                height: 30.0,
                                child: Row(
                                  children: [
                                    Text('${engine.locale('spirituality')}: '),
                                    isEditorMode
                                        ? Container(
                                            alignment: Alignment.topCenter,
                                            width: 40.0,
                                            height: 10.0,
                                            child: TextField(
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    3),
                                              ],
                                              keyboardType:
                                                  TextInputType.number,
                                              textAlign: TextAlign.center,
                                              controller:
                                                  _spiritualityController,
                                            ),
                                          )
                                        : Text('$spirituality'),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 30.0,
                                child: Row(
                                  children: [
                                    Text('${engine.locale('dexterity')}: '),
                                    isEditorMode
                                        ? Container(
                                            alignment: Alignment.topCenter,
                                            width: 40.0,
                                            height: 10.0,
                                            child: TextField(
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    3),
                                              ],
                                              keyboardType:
                                                  TextInputType.number,
                                              textAlign: TextAlign.center,
                                              controller: _dexterityController,
                                            ),
                                          )
                                        : Text('$dexterity'),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 30.0,
                                child: Row(
                                  children: [
                                    Text('${engine.locale('strength')}: '),
                                    isEditorMode
                                        ? Container(
                                            alignment: Alignment.topCenter,
                                            width: 40.0,
                                            height: 10.0,
                                            child: TextField(
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    3),
                                              ],
                                              keyboardType:
                                                  TextInputType.number,
                                              textAlign: TextAlign.center,
                                              controller: _strengthController,
                                            ),
                                          )
                                        : Text('$strength'),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 30.0,
                                child: Row(
                                  children: [
                                    Text('${engine.locale('willpower')}: '),
                                    isEditorMode
                                        ? Container(
                                            alignment: Alignment.topCenter,
                                            width: 40.0,
                                            height: 10.0,
                                            child: TextField(
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    3),
                                              ],
                                              keyboardType:
                                                  TextInputType.number,
                                              textAlign: TextAlign.center,
                                              controller: _willpowerController,
                                            ),
                                          )
                                        : Text('$willpower'),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 30.0,
                                child: Row(
                                  children: [
                                    Text('${engine.locale('perception')}: '),
                                    isEditorMode
                                        ? Container(
                                            alignment: Alignment.topCenter,
                                            width: 40.0,
                                            height: 10.0,
                                            child: TextField(
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    3),
                                              ],
                                              keyboardType:
                                                  TextInputType.number,
                                              textAlign: TextAlign.center,
                                              controller: _perceptionController,
                                            ),
                                          )
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 30.0,
                                child: Text('${engine.locale('fame')}: $fame'),
                              ),
                              SizedBox(
                                height: 30.0,
                                child:
                                    Text('${engine.locale('infamy')}: $infamy'),
                              ),
                              SizedBox(
                                height: 30.0,
                                child: Text(
                                    '${engine.locale('master')}: $masterName'),
                              ),
                              SizedBox(
                                height: 30.0,
                                child: Text(
                                    '${engine.locale('organization')}: $organizationId'),
                              ),
                              SizedBox(
                                height: 30.0,
                                child:
                                    Text('${engine.locale('title')}: $title'),
                              ),
                            ],
                          ),
                        ),
                        if (widget.showIntimacy)
                          Container(
                            padding: const EdgeInsets.only(top: 5.0),
                            width: 125.0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 30.0,
                                  child: Text(
                                    '${engine.locale('charismaFavor')}: ${_characterData['charismaFavor'].truncate()}',
                                  ),
                                ),
                                SizedBox(
                                  height: 30.0,
                                  child: Text(
                                    '${engine.locale('cultivationFavor')}: $cultivationFavor',
                                  ),
                                ),
                                SizedBox(
                                  height: 30.0,
                                  child: Text(
                                    '${engine.locale('organizationFavor')}: $organizationFavor',
                                  ),
                                ),
                                SizedBox(
                                  height: 30.0,
                                  child: Text(
                                      '${engine.locale('birthday')}: $birthday'),
                                ),
                                SizedBox(
                                  height: 30.0,
                                  child: Text(
                                      '${engine.locale('restLifespan')}: $restLifespan'),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (widget.showRelationships) ...[
                      const Divider(),
                      // Text('---${engine.locale('relationship')}---'),
                      Wrap(
                        alignment: WrapAlignment.start,
                        children: [
                          Label(
                            '${engine.locale('father')}: $father',
                            width: 125.0,
                            height: 30.0,
                          ),
                          Label(
                            '${engine.locale('mother')}: $mother',
                            width: 125.0,
                            height: 30.0,
                          ),
                          Label(
                            '${engine.locale('spouse')}: $spouse',
                            width: 125.0,
                            height: 30.0,
                          ),
                          LabelsWrap(
                            minWidth: 125.0,
                            minHeight: 30.0,
                            '${engine.locale('children')}: ',
                            children: childs,
                          ),
                          LabelsWrap(
                            minWidth: 125.0,
                            minHeight: 30.0,
                            '${engine.locale('siblings')}: ',
                            children: siblings,
                          ),
                          const Divider(
                            height: 0.0,
                            color: Colors.transparent,
                          ),
                        ],
                      ),
                    ],
                    if (widget.showPosition) ...[
                      const Divider(),
                      Wrap(
                        children: [
                          Label(
                            '${engine.locale('home')}: $home',
                            width: 125.0,
                            height: 30.0,
                          ),
                          Label(
                            '${engine.locale('location')}: $locationId',
                            width: 125.0,
                            height: 30.0,
                          ),
                          Label(
                            '${engine.locale('site')}: $siteId',
                            width: 125.0,
                            height: 30.0,
                          ),
                          Label(
                            '${engine.locale('worldPosition')}: $worldPositionString',
                            width: 125.0,
                            height: 30.0,
                          ),
                          Label(
                            '${engine.locale('world')}: $worldId',
                            width: 125.0,
                            height: 30.0,
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
                            ideal >= 0
                                ? '${engine.locale('ideal')}: $ideal'
                                : '${engine.locale('real')}: ${-ideal}',
                            width: 125.0,
                            height: 30.0,
                          ),
                          Label(
                            order >= 0
                                ? '${engine.locale('order')}: $order'
                                : '${engine.locale('chaotic')}: ${-order}',
                            width: 125.0,
                            height: 30.0,
                          ),
                          Label(
                            good >= 0
                                ? '${engine.locale('good')}: $good'
                                : '${engine.locale('evil')}: ${-good}',
                            width: 125.0,
                            height: 30.0,
                          ),
                          Label(
                            social >= 0
                                ? '${engine.locale('extraversion')}: $social'
                                : '${engine.locale('introspection')}: ${-social}',
                            width: 125.0,
                            height: 30.0,
                          ),
                          Label(
                            reason >= 0
                                ? '${engine.locale('reasoning')}: $reason'
                                : '${engine.locale('feeling')}: ${-reason}',
                            width: 125.0,
                            height: 30.0,
                          ),
                          Label(
                            control >= 0
                                ? '${engine.locale('organizing')}: $control'
                                : '${engine.locale('relaxing')}: ${-control}',
                            width: 125.0,
                            height: 30.0,
                          ),
                          Label(
                            frugal >= 0
                                ? '${engine.locale('frugality')}: $frugal'
                                : '${engine.locale('lavishness')}: ${-frugal}',
                            width: 125.0,
                            height: 30.0,
                          ),
                          Label(
                            frank >= 0
                                ? '${engine.locale('frankness')}: $frank'
                                : '${engine.locale('tactness')}: ${-frank}',
                            width: 125.0,
                            height: 30.0,
                          ),
                          Label(
                            confidence >= 0
                                ? '${engine.locale('confidence')}: $confidence'
                                : '${engine.locale('cowardness')}: ${-confidence}',
                            width: 125.0,
                            height: 30.0,
                          ),
                          Label(
                            prudence >= 0
                                ? '${engine.locale('prudence')}: $prudence'
                                : '${engine.locale('adventurousness')}: ${-prudence}',
                            width: 125.0,
                            height: 30.0,
                          ),
                          Label(
                            empathy >= 0
                                ? '${engine.locale('empathy')}: $empathy'
                                : '${engine.locale('indifference')}: ${-empathy}',
                            width: 125.0,
                            height: 30.0,
                          ),
                          Label(
                            generosity >= 0
                                ? '${engine.locale('generosity')}: $generosity'
                                : '${engine.locale('stinginess')}: ${-generosity}',
                            width: 125.0,
                            height: 30.0,
                          ),
                          // const Divider(
                          //   color: Colors.transparent,
                          //   height: 0.0,
                          // ),
                          LabelsWrap(
                            '${engine.locale('motivation')}:',
                            minWidth: 125.0,
                            minHeight: 30.0,
                            children: motivations,
                          ),
                          LabelsWrap(
                            '${engine.locale('thinking')}:',
                            minWidth: 125.0,
                            minHeight: 30.0,
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
            ),
            Row(
              children: [
                if (widget.mode != ViewPanelMode.view) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0, left: 10.0),
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => EditCharacterIdAndAvatar(
                            id: _characterData['id'],
                            name: _characterData['shortName'],
                            skin: _characterData['skin'],
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
                            _characterData['skin'] = skin ?? 'default';
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
                ],
                const Spacer(),
                if (widget.mode != ViewPanelMode.view)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0, right: 10.0),
                    child: ElevatedButton(
                      onPressed: () {
                        switch (widget.mode) {
                          case ViewPanelMode.select:
                            Navigator.of(context).pop(_characterData['id']);
                          case ViewPanelMode.edit:
                            _saveData();
                            Navigator.of(context).pop(true);
                          case ViewPanelMode.create:
                            _saveData();
                            Navigator.of(context).pop(_characterData);
                          case ViewPanelMode.view:
                            Navigator.of(context).pop();
                        }
                      },
                      child: Text(engine.locale('confirm')),
                    ),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

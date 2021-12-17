import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CharacterEditor extends StatefulWidget {
  const CharacterEditor({Key? key, required this.onClosed, this.data})
      : super(key: key);

  final Map<String, dynamic>? data;

  final void Function(Map<String, dynamic>? data) onClosed;

  @override
  _CharacterEditorState createState() => _CharacterEditorState();
}

class _CharacterEditorState extends State<CharacterEditor> {
  Map<String, dynamic>? get data => widget.data;

  final _nameTextFieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.characterEditor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.onClosed(null);
          },
          tooltip: AppLocalizations.of(context)!.goBack,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            widget.onClosed(data);
          });
        },
        label: Text(AppLocalizations.of(context)!.save),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueGrey,
      ),
      body: Scrollbar(
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
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText:
                                AppLocalizations.of(context)!.characterId,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText:
                                AppLocalizations.of(context)!.characterName,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText:
                                AppLocalizations.of(context)!.characterAvatar,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText: AppLocalizations.of(context)!
                                .characterOrganization,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText: AppLocalizations.of(context)!
                                .characterRankInOrganization,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText: AppLocalizations.of(context)!
                                .characterSuperiorInOrganization,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText: AppLocalizations.of(context)!
                                .characterLoyaltyInOrganization,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText: AppLocalizations.of(context)!
                                .characterAllegianceTo,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText: AppLocalizations.of(context)!
                                .characterAllegiance,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText:
                                AppLocalizations.of(context)!.characterFame,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText:
                                AppLocalizations.of(context)!.characterInfamy,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText:
                                AppLocalizations.of(context)!.characterLooks,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText: AppLocalizations.of(context)!
                                .characterCurrentLife,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText:
                                AppLocalizations.of(context)!.characterSpirit,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText: AppLocalizations.of(context)!
                                .characterCurrentSpirit,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText:
                                AppLocalizations.of(context)!.characterStamina,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText: AppLocalizations.of(context)!
                                .characterCurrentStamina,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText:
                                AppLocalizations.of(context)!.characterStrength,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText: AppLocalizations.of(context)!
                                .characterDexterity,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText: AppLocalizations.of(context)!
                                .characterPerception,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText: AppLocalizations.of(context)!
                                .characterIntelligence,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText:
                                AppLocalizations.of(context)!.characterMemory,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText: AppLocalizations.of(context)!
                                .characterWaterSpiritRoot,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText: AppLocalizations.of(context)!
                                .characterWoodSpiritRoot,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText: AppLocalizations.of(context)!
                                .characterEarthSpiritRoot,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText: AppLocalizations.of(context)!
                                .characterMetalSpiritRoot,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 400,
                        child: TextFormField(
                          controller: _nameTextFieldController,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText: AppLocalizations.of(context)!
                                .characterFireSpiritRoot,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

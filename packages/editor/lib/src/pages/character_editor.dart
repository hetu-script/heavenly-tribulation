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
      body: Container(
        padding: const EdgeInsets.all(15.0),
        width: 400,
        child: Column(
          children: [
            TextFormField(
              controller: _nameTextFieldController,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: AppLocalizations.of(context)!.characterId,
              ),
            ),
            TextFormField(
              controller: _nameTextFieldController,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: AppLocalizations.of(context)!.characterName,
              ),
            ),
            TextFormField(
              controller: _nameTextFieldController,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: AppLocalizations.of(context)!.characterAvatar,
              ),
            ),
            TextFormField(
              controller: _nameTextFieldController,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: AppLocalizations.of(context)!.characterOrganization,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

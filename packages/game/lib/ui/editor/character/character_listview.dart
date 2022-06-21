import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';

import '../../../global.dart';
import '../../shared/empty_placeholder.dart';
import 'character_editor.dart';
import '../../../shared/util.dart' as util;
import '../../../shared/json.dart';
import '../../shared/avatar.dart';

class CharacterListView extends StatefulWidget {
  const CharacterListView({
    super.key,
    required this.data,
    required this.onSaved,
  });

  final List<Map<String, dynamic>> data;

  final void Function(String content) onSaved;

  @override
  State<CharacterListView> createState() => _CharacterListViewState();
}

class _CharacterListViewState extends State<CharacterListView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  GameLocalization get locale => engine.locale;

  List<Map<String, dynamic>> get data => widget.data;

  Map<String, dynamic>? _currentEditingCharacterData;

  List<Widget>? _characterCards;

  bool _isEditing = false;

  void _onEditorClosed(bool saved) {
    setState(() {
      _isEditing = false;
      if (saved) {
        _updateData();
        final encode = jsonEncodeWithIndent(data);
        widget.onSaved(encode);
      }
    });
  }

  Future<void> _updateData() async {
    _characterCards = data.map((Map<String, dynamic> charData) {
      final String name = charData['characterName'];
      final String avatar = charData['characterAvatar'];
      return
          // Ink(
          //   width: 100.0,
          //   height: 100.0,
          //   decoration: BoxDecoration(
          //     borderRadius: BorderRadius.circular(8.0),
          //     image: DecorationImage(
          //       image: AssetImage('assets/images/$avatar'),
          //       fit: BoxFit.fill,
          //     ),
          //   ),
          //   child:
          InkWell(
        splashColor: Colors.blue.withAlpha(30),
        onTap: () {
          setState(() {
            _currentEditingCharacterData = charData;
            _isEditing = true;
          });
        },
        child: Avatar(
          avatarAssetKey: 'assets/images/$avatar',
          name: name,
        ),
        // ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isEditing) {
      return CharacterEditor(
        data: _currentEditingCharacterData!,
        onClosed: _onEditorClosed,
        maleAvatarCount: 37, // number of the male avatar images
        femaleAvatarCount: 75, // number of the female avatar images
      );
    } else {
      return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            setState(() {
              data.add({'characterId': 'custom_character_${util.uid()}'});
              _currentEditingCharacterData = data.last;
              _isEditing = true;
            });
          },
          label: Text(locale['create']),
          icon: const Icon(Icons.add),
          backgroundColor: Colors.blue,
        ),
        body: Container(
          padding: const EdgeInsets.all(15.0),
          child: RefreshIndicator(
            // key: _refreshIndicatorKey,
            onRefresh: _updateData,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
              ),
              child: SingleChildScrollView(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  shrinkWrap: true,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: (_characterCards != null &&
                                _characterCards!.isNotEmpty)
                            ? Wrap(
                                spacing: 8.0, // gap between adjacent chips
                                runSpacing: 4.0, // gap between lines
                                children: _characterCards!)
                            : EmptyPlaceholder(engine.locale['empty']),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}

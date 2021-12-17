import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../empty_placeholder.dart';
import 'character_editor.dart';

class CharacterListView extends StatefulWidget {
  const CharacterListView({required this.data, Key? key}) : super(key: key);

  final List<Map<String, dynamic>> data;

  @override
  _CharacterListViewState createState() => _CharacterListViewState();
}

class _CharacterListViewState extends State<CharacterListView> {
  List<Map<String, dynamic>> get data => widget.data;

  final _characterCards = <Widget>[];

  bool _isEditing = false;

  void _onEditorClosed(Map<String, dynamic>? data) {
    setState(() {
      _isEditing = false;
      if (data == null) {}
    });
  }

  Future<void> updateData() async {
    _characterCards.clear();

    // _sceneCards = scenesData?.values.map((value) {
    //   final sceneData = value as Map<String, dynamic>;
    //   final String id = sceneData['id'];
    //   final String type = sceneData['type'];
    //   final titleId = sceneData['name'];
    //   String title;
    //   if (titleId == null) {
    //     title = _getDefaultTitle(type);
    //   } else {
    //     title = game.texts[titleId];
    //   }
    //   String? image = sceneData['image'];
    //   image ??= _getDefaultImagePath(type);

    //   return SizedBox(
    //     width: 210,
    //     height: 150,
    //     child: Card(
    //       elevation: 8.0,
    //       shadowColor: Colors.black26,
    //       child: Ink(
    //         decoration: BoxDecoration(
    //           borderRadius: BorderRadius.circular(8.0),
    //           image: DecorationImage(
    //             image: AssetImage('assets/images/$image'),
    //             fit: BoxFit.cover,
    //           ),
    //         ),
    //         child: InkWell(
    //           splashColor: Colors.blue.withAlpha(30),
    //           onTap: () {
    //             game.hetu
    //                 .invoke('handleSceneInteraction', positionalArgs: [id]);
    //           },
    //           child: Padding(
    //             padding: const EdgeInsets.all(8.0),
    //             child: Column(
    //               crossAxisAlignment: CrossAxisAlignment.start,
    //               children: <Widget>[
    //                 Container(
    //                   color: Colors.white.withOpacity(0.5),
    //                   child: Text(title),
    //                 ),
    //               ],
    //             ),
    //           ),
    //         ),
    //       ),
    //     ),
    //   );
    // }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return CharacterEditor(
        onClosed: _onEditorClosed,
      );
    } else {
      return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            setState(() {
              _isEditing = true;
            });
          },
          label: Text(AppLocalizations.of(context)!.create),
          icon: const Icon(Icons.add),
          backgroundColor: Colors.blueGrey,
        ),
        body: Container(
          padding: const EdgeInsets.all(15.0),
          child: RefreshIndicator(
            // key: _refreshIndicatorKey,
            onRefresh: updateData,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
              ),
              child: Scrollbar(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  shrinkWrap: true,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: (_characterCards.isNotEmpty
                            ? Wrap(
                                spacing: 8.0, // gap between adjacent chips
                                runSpacing: 4.0, // gap between lines
                                children: _characterCards)
                            : EmptyPlaceholder(
                                text: AppLocalizations.of(context)!.empty)),
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

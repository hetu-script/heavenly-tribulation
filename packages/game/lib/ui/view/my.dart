import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';

import '../../../global.dart';
import '../shared/avatar.dart';

class MyView extends StatefulWidget {
  final VoidCallback onQuit;

  const MyView({
    Key? key,
    required this.onQuit,
  }) : super(key: key);

  @override
  _MyViewState createState() => _MyViewState();
}

class _MyViewState extends State<MyView> {
  GameLocalization get locale => engine.locale;

  late String _name, _avatarPath;

  Future<void> _updateData() async {
    engine.invoke('nextTick');

    final data = engine.hetu.interpreter
        .invoke('getCharacterById', positionalArgs: ['current']);

    setState(() {
      final String? name = data['name'];
      if (name != null) {
        _name = name;
      } else {
        final String nameId = data['nameId'];
        _name = engine.locale[nameId];
      }
      _avatarPath = 'assets/images/${data['avatar']}';
    });
  }

  @override
  void initState() {
    super.initState();
    _updateData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        // key: _refreshIndicatorKey,
        onRefresh: _updateData,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            },
          ),
          child: Scrollbar(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.fill,
                  image: AssetImage('assets/images/interior/home.jpg'),
                ),
              ),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                children: <Widget>[
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 160,
                        ),
                        Avatar(
                          avatarAssetKey: _avatarPath,
                          radius: 50,
                        ),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: kBorderRadius,
                          ),
                          child: SizedBox(
                            width: 400.0,
                            child: Column(
                              children: <Widget>[
                                Text(
                                  _name,
                                  style: const TextStyle(fontSize: 20.0),
                                ),
                                const Text(
                                    'A sufficiently long subtitle warrants three lines.'),
                              ],
                            ),
                          ),
                        ),
                        Column(
                          children: <Widget>[
                            ElevatedButton(
                              onPressed: () {
                                widget.onQuit();
                              },
                              child: Text(locale['quit']),
                            ),
                          ],
                        ),
                      ],
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

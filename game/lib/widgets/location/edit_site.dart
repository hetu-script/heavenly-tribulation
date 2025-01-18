import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_panel.dart';
import 'package:samsara/ui/close_button2.dart';

import '../../engine.dart';
import '../../data.dart';
import '../../ui.dart';

class EditSite extends StatefulWidget {
  const EditSite({
    super.key,
  });

  @override
  State<EditSite> createState() => _EditSiteState();
}

class _EditSiteState extends State<EditSite> {
  String? _selectedValue;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _selectedValue = GameData.constructableSiteCategoryNames.keys.first;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsivePanel(
      alignment: AlignmentDirectional.center,
      child: SizedBox(
        width: 240,
        height: 170,
        child: Scaffold(
          backgroundColor: GameUI.backgroundColor,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(engine.locale('selectOne')),
            actions: const [CloseButton2()],
          ),
          body: Container(
            alignment: AlignmentDirectional.center,
            child: Column(
              children: [
                Container(
                  width: 180.0,
                  height: 80,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 20.0),
                  child: DropdownButton<String>(
                      value: _selectedValue,
                      items: GameData.constructableSiteCategoryNames.keys
                          .map(
                            (key) => DropdownMenuItem<String>(
                              value: key,
                              child: Text(GameData
                                  .constructableSiteCategoryNames[key]!),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedValue = value;
                        });
                      }),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(_selectedValue);
                    },
                    child: Text(
                      engine.locale('confirm'),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

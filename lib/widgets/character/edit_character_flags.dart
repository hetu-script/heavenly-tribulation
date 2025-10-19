import 'package:flutter/material.dart';
import 'package:samsara/widgets/ui/responsive_view.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../../ui.dart';
import '../ui/close_button2.dart';

class EditCharacterFlags extends StatefulWidget {
  const EditCharacterFlags({
    super.key,
    required this.character,
  });

  final dynamic character;

  @override
  State<EditCharacterFlags> createState() => _EditCharacterFlagsState();
}

class _EditCharacterFlagsState extends State<EditCharacterFlags> {
  final flags = {
    'useCustomLogic': false,
  };

  @override
  void initState() {
    super.initState();

    for (final key in flags.keys) {
      flags[key] = widget.character[key] ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      alignment: Alignment.center,
      backgroundColor: GameUI.backgroundColor2,
      width: 400,
      height: 400,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('terrain')),
          actions: const [CloseButton2()],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            children: [
              SizedBox(
                width: 380,
                height: 300,
                child: ListView(
                  children: flags.keys
                      .map(
                        (flag) => SizedBox(
                          width: 380,
                          height: 40,
                          child: Row(
                            children: [
                              fluent.Checkbox(
                                checked: flags[flag],
                                onChanged: (newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      flags[flag] = newValue;
                                    });
                                  }
                                },
                              ),
                              Text(flag),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0, right: 10.0),
                  child: fluent.FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop(flags);
                    },
                    child: Text(engine.locale('confirm')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

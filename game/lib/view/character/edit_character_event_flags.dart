import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_window.dart';
import 'package:samsara/ui/close_button.dart';

import '../../engine.dart';
import '../../ui.dart';

class EditCharacterEventFlags extends StatefulWidget {
  const EditCharacterEventFlags({
    super.key,
    required this.flagsData,
  });

  final dynamic flagsData;

  @override
  State<EditCharacterEventFlags> createState() =>
      _EditCharacterEventFlagsState();
}

class _EditCharacterEventFlagsState extends State<EditCharacterEventFlags> {
  final flags = {
    'useCustomInteraction': false,
  };

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    for (final key in flags.keys) {
      flags[key] = widget.flagsData[key] ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWindow(
      alignment: Alignment.center,
      color: kBackgroundColor,
      size: const Size(400, 400),
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
                              Checkbox(
                                value: flags[flag],
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
                  child: ElevatedButton(
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

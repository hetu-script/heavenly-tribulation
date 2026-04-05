import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:samsara/widgets/ui/empty_placeholder.dart';

import '../../global.dart';
import '../../ui.dart';
import '../../widgets/ui/close_button2.dart';
import '../../widgets/ui/responsive_view.dart';

class ModsListDialog extends StatefulWidget {
  const ModsListDialog({super.key});

  @override
  State<ModsListDialog> createState() => _ModsListDialogState();
}

class _ModsListDialogState extends State<ModsListDialog> {
  late Map<String, dynamic> _mods;

  @override
  void initState() {
    super.initState();
    // 深拷贝当前 mods 配置
    _mods = {};
    for (final entry in engine.config.mods.entries) {
      if (entry.value is Map) {
        _mods[entry.key] = Map<String, dynamic>.from(entry.value as Map);
      } else {
        _mods[entry.key] = entry.value;
      }
    }
  }

  Future<void> _applyMods() async {
    await gameConfig.updateConfig(mods: _mods);
  }

  @override
  Widget build(BuildContext context) {
    final modEntries = _mods.entries.toList();

    return ResponsiveView(
      width: 600.0,
      height: 450.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('modsList')),
          actions: [
            CloseButton2(
              onPressed: () {
                Navigator.of(context).maybePop();
              },
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(5.0),
                child: modEntries.isNotEmpty
                    ? SingleChildScrollView(
                        child: ListView(
                          shrinkWrap: true,
                          children: modEntries
                              .map(
                                (entry) => Card(
                                  color: GameUI.backgroundColor,
                                  shape: GameUI.roundedRectangleBorder,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                entry.key,
                                                style: const TextStyle(
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        fluent.ToggleSwitch(
                                          checked: entry.value is Map &&
                                              entry.value['enabled'] == true,
                                          onChanged: (bool value) {
                                            setState(() {
                                              if (_mods[entry.key] is Map) {
                                                (_mods[entry.key]
                                                    as Map)['enabled'] = value;
                                              } else {
                                                _mods[entry.key] = {
                                                  'enabled': value
                                                };
                                              }
                                            });
                                          },
                                          content: Text(
                                            engine.locale(
                                              entry.value is Map &&
                                                      entry.value['enabled'] ==
                                                          true
                                                  ? 'enabled'
                                                  : 'disabled',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      )
                    : EmptyPlaceholder(
                        engine.locale('noModsFound'),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: fluent.Button(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(engine.locale('cancel')),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: fluent.FilledButton(
                      onPressed: () async {
                        await _applyMods();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(engine.locale('save')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

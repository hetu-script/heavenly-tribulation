import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/widgets/ui/responsive_view.dart';
import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../entity_listview.dart';
import '../../engine.dart';
import '../../ui.dart';
import '../ui/close_button2.dart';

class EditCharacterBond extends StatefulWidget {
  const EditCharacterBond({
    super.key,
    this.enableTargetEdit = true,
    this.targetCharacterId,
    this.score,
    this.haveMet,
  });

  final bool enableTargetEdit;
  final String? targetCharacterId;
  final int? score;
  final bool? haveMet;

  @override
  State<EditCharacterBond> createState() => _EditCharacterBondState();
}

class _EditCharacterBondState extends State<EditCharacterBond> {
  final _targetCharacterIdEditingController = TextEditingController();
  final _scoreEditingController = TextEditingController();
  bool _haveMetValue = false;

  @override
  void initState() {
    super.initState();

    _targetCharacterIdEditingController.text = widget.targetCharacterId ?? '';
    _scoreEditingController.text = widget.score?.toString() ?? '0';

    _haveMetValue = widget.haveMet ?? false;
  }

  @override
  void dispose() {
    super.dispose();

    _targetCharacterIdEditingController.dispose();
    _scoreEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.center,
      width: 350.0,
      height: 400.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            engine.locale('edit'),
          ),
          actions: const [CloseButton2()],
        ),
        body: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    width: 330.0,
                    height: 40.0,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(top: 15.0),
                          width: 90.0,
                          child: Text(
                            '${engine.locale('characterId')}: ',
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.only(right: 20.0),
                          width: 120.0,
                          height: 40.0,
                          child: TextField(
                            enabled: widget.enableTargetEdit,
                            controller: _targetCharacterIdEditingController,
                          ),
                        ),
                        fluent.FilledButton(
                          onPressed: widget.enableTargetEdit
                              ? () async {
                                  final key = await showDialog<String>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => EntityListView(
                                      showCloseButton: false,
                                      mode: EntityListViewMode.selectCharacter,
                                    ),
                                  );
                                  _targetCharacterIdEditingController.text =
                                      key ?? '';
                                }
                              : null,
                          child: Text(engine.locale('select')),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 330.0,
                    height: 40.0,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 90.0,
                          child: Text('${engine.locale('favorScore')}: '),
                        ),
                        SizedBox(
                          width: 100.0,
                          height: 40.0,
                          child: TextField(
                            textAlign: TextAlign.center,
                            controller: _scoreEditingController,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 330.0,
                    height: 40.0,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(top: 20.0, left: 85.0),
                          width: 190.0,
                          height: 40.0,
                          child: Row(
                            children: [
                              fluent.Checkbox(
                                checked: _haveMetValue,
                                onChanged: (newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _haveMetValue = newValue;
                                    });
                                  }
                                },
                              ),
                              Text(engine.locale('haveMet')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: fluent.FilledButton(
                  onPressed: () {
                    String? id =
                        _targetCharacterIdEditingController.text.nonEmptyValue;
                    int score = int.tryParse(_scoreEditingController.text) ?? 0;

                    if (id != null) {
                      Navigator.of(context).pop((id, score, _haveMetValue));
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(
                    engine.locale('confirm'),
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

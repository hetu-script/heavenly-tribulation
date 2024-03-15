import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';

class CreateBlankMapDialog extends StatefulWidget {
  static Future<dynamic> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) => const CreateBlankMapDialog(),
    );
  }

  const CreateBlankMapDialog({super.key});

  @override
  State<CreateBlankMapDialog> createState() => _CreateBlankMapDialogState();
}

class _CreateBlankMapDialogState extends State<CreateBlankMapDialog> {
  final _filaNameEditingController = TextEditingController();
  final _idEditingController = TextEditingController();
  final _mapWidthEditingController = TextEditingController();
  final _mapHeightEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _filaNameEditingController.text = engine.locale('unnamedMap');
    _idEditingController.text = 'main';
    _mapWidthEditingController.text = '12';
    _mapHeightEditingController.text = '12';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(engine.locale('newMap')),
        // actions: const [CloseButton()],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: ListView(
                shrinkWrap: true,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      children: [
                        SizedBox(
                          width: 250,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 100.0,
                                child: Text('${engine.locale('fileName')}: '),
                              ),
                              SizedBox(
                                width: 150.0,
                                child: TextField(
                                  controller: _filaNameEditingController,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 250,
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 100.0,
                                child: Text('ID: '),
                              ),
                              SizedBox(
                                width: 150.0,
                                child: TextField(
                                  controller: _idEditingController,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 240,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 100.0,
                                child: Text('${engine.locale('mapSize')}: '),
                              ),
                              SizedBox(
                                width: 50.0,
                                child: TextField(
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  controller: _mapWidthEditingController,
                                ),
                              ),
                              const Text(' × '),
                              SizedBox(
                                width: 50.0,
                                child: TextField(
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  controller: _mapHeightEditingController,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(engine.locale('cancel')),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'fileName': _filaNameEditingController.text,
                      'id': _idEditingController.text,
                      'width': int.parse(_mapWidthEditingController.text),
                      'height': int.parse(_mapHeightEditingController.text),
                      'method': 'blank',
                      'isEditorMode': true,
                    });
                  },
                  child: Text(engine.locale('continue')),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // return ResponsiveWindow(
    //   alignment: AlignmentDirectional.center,
    //   child: layout,
    // );
  }
}

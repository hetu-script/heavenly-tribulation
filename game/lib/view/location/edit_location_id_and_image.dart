import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_window.dart';
import 'package:samsara/ui/close_button.dart';
import 'package:samsara/extensions.dart' show StringEx;

import '../../config.dart';

class EditLocationIdAndBackground extends StatefulWidget {
  const EditLocationIdAndBackground({
    super.key,
    required this.id,
    required this.name,
    this.backgroundPath,
  });

  final String id;
  final String name;
  final String? backgroundPath;

  @override
  State<EditLocationIdAndBackground> createState() =>
      _EditLocationIdAndBackgroundState();
}

class _EditLocationIdAndBackgroundState
    extends State<EditLocationIdAndBackground> {
  final _idEditingController = TextEditingController();
  final _nameEditingController = TextEditingController();
  final _backgroundEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _idEditingController.text = widget.id;
    _nameEditingController.text = widget.name;
    _backgroundEditingController.text = widget.backgroundPath ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWindow(
      color: kBackgroundColor,
      alignment: AlignmentDirectional.center,
      size: const Size(350.0, 400.0),
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
          padding: const EdgeInsets.only(top: 20.0),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 280.0,
                    height: 40.0,
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 90.0,
                          child: Text('ID'),
                        ),
                        SizedBox(
                          width: 190.0,
                          height: 40.0,
                          child: TextField(
                            controller: _idEditingController,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 150.0,
                    height: 40.0,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 90.0,
                          child: Text('${engine.locale('name')}: '),
                        ),
                        SizedBox(
                          width: 190.0,
                          height: 40.0,
                          child: TextField(
                            controller: _nameEditingController,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 280.0,
                    height: 40.0,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 90.0,
                          child: Text('${engine.locale('background')}: '),
                        ),
                        SizedBox(
                          width: 190.0,
                          height: 40.0,
                          child: TextField(
                            controller: _backgroundEditingController,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: ElevatedButton(
                  onPressed: () {
                    String? id = _idEditingController.text.nonEmptyValueOrNull;
                    String? name =
                        _nameEditingController.text.nonEmptyValueOrNull;
                    String? background =
                        _backgroundEditingController.text.nonEmptyValueOrNull;

                    Navigator.of(context).pop((
                      id,
                      name,
                      background,
                    ));
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

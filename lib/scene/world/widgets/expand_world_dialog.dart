import 'package:flutter/material.dart';
// import 'package:samsara/ui/ink_button.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:samsara/ui/integer_input_field.dart';
import 'package:samsara/ui/close_button2.dart';

import '../../../engine.dart';
import '../../../game/ui.dart';

const kDirections = {
  'topLeft',
  'topCenter',
};

class ExpandWorldDialog extends StatefulWidget {
  const ExpandWorldDialog({
    super.key,
    this.defaultX,
    this.defaultY,
    this.maxX,
    this.maxY,
    this.title,
  });

  final int? defaultX, defaultY;
  final int? maxX, maxY;
  final String? title;

  @override
  State<ExpandWorldDialog> createState() => _ExpandWorldDialogState();
}

class _ExpandWorldDialogState extends State<ExpandWorldDialog> {
  final _posXController = TextEditingController();
  final _posYController = TextEditingController();

  String direction = 'bottomRight';

  @override
  void initState() {
    super.initState();

    _posXController.text = widget.defaultX?.toString() ?? '';
    _posYController.text = widget.defaultY?.toString() ?? '';
  }

  @override
  void dispose() {
    super.dispose();

    _posXController.dispose();
    _posYController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      width: 250.0,
      height: 160.0,
      alignment: AlignmentDirectional.center,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.title ?? engine.locale('input')),
          actions: const [CloseButton2()],
        ),
        body: Container(
          alignment: AlignmentDirectional.center,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100.0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 20.0),
                    child: IntegerInputField(
                      autofocus: true,
                      initValue: widget.defaultX,
                      min: 0,
                      max: widget.maxX,
                      controller: _posXController,
                    ),
                  ),
                  Container(
                    width: 100.0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 20.0),
                    child: IntegerInputField(
                      initValue: widget.defaultY,
                      min: 0,
                      max: widget.maxY,
                      controller: _posYController,
                    ),
                  ),
                ],
              ),
              // Container(
              //   width: 89,
              //   height: 89,
              //   decoration: BoxDecoration(
              //     borderRadius: BorderRadius.circular(5.0),
              //   ),
              //   child: Wrap(
              //     children: [
              //       Padding(
              //         padding: const EdgeInsets.all(2.0),
              //         child: InkButton(
              //           isEnabled: false,
              //           isSelected: direction == 'topLeft',
              //           size: const Size(25, 25),
              //           onPressed: () {
              //             setState(() {
              //               direction = 'topLeft';
              //             });
              //           },
              //           child: const Icon(Icons.north_west),
              //         ),
              //       ),
              //       Padding(
              //         padding: const EdgeInsets.all(2.0),
              //         child: InkButton(
              //           isSelected: direction == 'topCenter',
              //           size: const Size(25, 25),
              //           onPressed: () {
              //             setState(() {
              //               direction = 'topCenter';
              //             });
              //           },
              //           child: const Icon(Icons.north),
              //         ),
              //       ),
              //       Padding(
              //         padding: const EdgeInsets.all(2.0),
              //         child: InkButton(
              //           isEnabled: false,
              //           isSelected: direction == 'topRight',
              //           size: const Size(25, 25),
              //           onPressed: () {
              //             setState(() {
              //               direction = 'topRight';
              //             });
              //           },
              //           child: const Icon(Icons.north_east),
              //         ),
              //       ),
              //       Padding(
              //         padding: const EdgeInsets.all(2.0),
              //         child: InkButton(
              //           isEnabled: false,
              //           isSelected: direction == 'centerLeft',
              //           size: const Size(25, 25),
              //           onPressed: () {
              //             setState(() {
              //               direction = 'centerLeft';
              //             });
              //           },
              //           child: const Icon(Icons.west),
              //         ),
              //       ),
              //       Padding(
              //         padding: const EdgeInsets.all(2.0),
              //         child: InkButton(
              //           isSelected: direction == 'center',
              //           size: const Size(25, 25),
              //           onPressed: () {
              //             setState(() {
              //               direction = 'center';
              //             });
              //           },
              //           child: const Icon(Icons.radio_button_unchecked),
              //         ),
              //       ),
              //       Padding(
              //         padding: const EdgeInsets.all(2.0),
              //         child: InkButton(
              //           isEnabled: false,
              //           isSelected: direction == 'centerRight',
              //           size: const Size(25, 25),
              //           onPressed: () {
              //             setState(() {
              //               direction = 'centerRight';
              //             });
              //           },
              //           child: const Icon(Icons.east),
              //         ),
              //       ),
              //       Padding(
              //         padding: const EdgeInsets.all(2.0),
              //         child: InkButton(
              //           isEnabled: false,
              //           isSelected: direction == 'bottomLeft',
              //           size: const Size(25, 25),
              //           onPressed: () {
              //             setState(() {
              //               direction = 'bottomLeft';
              //             });
              //           },
              //           child: const Icon(Icons.south_west),
              //         ),
              //       ),
              //       Padding(
              //         padding: const EdgeInsets.all(2.0),
              //         child: InkButton(
              //           isEnabled: false,
              //           isSelected: direction == 'bottomCenter',
              //           size: const Size(25, 25),
              //           onPressed: () {
              //             setState(() {
              //               direction = 'bottomCenter';
              //             });
              //           },
              //           child: const Icon(Icons.south),
              //         ),
              //       ),
              //       Padding(
              //         padding: const EdgeInsets.all(2.0),
              //         child: InkButton(
              //           isSelected: direction == 'bottomRight',
              //           size: const Size(25, 25),
              //           onPressed: () {
              //             setState(() {
              //               direction = 'bottomRight';
              //             });
              //           },
              //           child: const Icon(Icons.south_east),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton(
                  onPressed: () {
                    final x = int.tryParse(_posXController.text);
                    final y = int.tryParse(_posYController.text);
                    (int, int, String)? result;
                    if (x != null && y != null) {
                      result = (x, y, direction);
                    }
                    Navigator.of(context).pop(result);
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
    );
  }
}

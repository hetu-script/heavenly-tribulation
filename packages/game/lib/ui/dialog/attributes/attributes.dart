import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../global.dart';

class AttributesView extends StatelessWidget {
  static Future<dynamic> show(
    BuildContext context,
    HTStruct data,
  ) async {
    return await showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) {
        return AttributesView(data: data);
      },
      barrierDismissible: true,
    );
  }

  final HTStruct data;

  const AttributesView({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
      },
      child: Material(
        type: MaterialType.transparency,
        child: ConstrainedBox(
          constraints: BoxConstraints.loose(
            Size(
              MediaQuery.of(context).size.width - 20,
              MediaQuery.of(context).size.height - 20,
            ),
          ),
          child: Container(
            height: 240,
            decoration: BoxDecoration(
              color: kBackgroundColor,
              borderRadius: kBorderRadius,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(children: <Widget>[
                Text(data['name']),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

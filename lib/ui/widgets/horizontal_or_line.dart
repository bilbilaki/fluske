import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class HorizontalOrLine extends StatelessWidget {
  const HorizontalOrLine({this.label, this.height, this.dividerColor});

  final String? label;
  final double? height;

  final Color? dividerColor;

  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
      Expanded(
        child: new Container(
            margin: const EdgeInsets.only(left: 20.0, right: 15.0),
            child: Divider(
              color: dividerColor,
              height: height,
            )),
      ),
      Text(label!),
      Expanded(
        child: new Container(
            margin: const EdgeInsets.only(left: 15.0, right: 20.0),
            child: Divider(
              color: dividerColor,
              height: height,
            )),
      ),
    ]);
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../../logic/logic.dart';
import '../../data/common.dart';
import '../ui/close_button2.dart';
import '../ui/responsive_view.dart';

class EditRankLevelSliderDialog extends StatefulWidget {
  static Future<(int, int)?> show({
    required BuildContext context,
    required int level,
    required int rank,
  }) {
    return showDialog<(int, int)?>(
      context: context,
      builder: (context) {
        return EditRankLevelSliderDialog(
          level: level,
          rank: rank,
        );
      },
    );
  }

  const EditRankLevelSliderDialog({
    super.key,
    required this.level,
    required this.rank,
  });

  final int level;
  final int rank;

  @override
  State<EditRankLevelSliderDialog> createState() =>
      _EditRankLevelSliderDialogState();
}

class _EditRankLevelSliderDialogState extends State<EditRankLevelSliderDialog> {
  late int _level;
  late int _minLevel, _maxLevel;
  late int _rank;

  @override
  void initState() {
    super.initState();

    setLevel(level: widget.level, rank: widget.rank);
  }

  void setLevel({int? level, int? rank}) {
    if (rank != null) {
      _rank = rank;
      _minLevel = GameLogic.minLevelForRank(_rank);
      _maxLevel = GameLogic.maxLevelForRank(_rank);
    }

    _level = (level ?? _level).clamp(_minLevel, _maxLevel);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      width: 400,
      height: 250,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('setRankLevel')),
          actions: const [CloseButton2()],
        ),
        body: Container(
          alignment: AlignmentDirectional.center,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10.0, left: 20.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120.0,
                      child: Text(engine.locale('cultivationLevel')),
                    ),
                    Slider(
                      value: _level.toDouble(),
                      min: _minLevel.toDouble(),
                      max: _maxLevel.toDouble(),
                      onChanged: (double value) {
                        setState(() {
                          setLevel(level: value.toInt());
                        });
                      },
                    ),
                    SizedBox(
                      child: Text(_level.toString()),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0, left: 20.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120.0,
                      child: Text(engine.locale('cultivationRank')),
                    ),
                    Slider(
                      value: _rank.toDouble(),
                      min: 0.0,
                      max: kCultivationRankMax.toDouble(),
                      onChanged: (double value) {
                        setState(() {
                          setLevel(rank: value.toInt());
                        });
                      },
                    ),
                    SizedBox(
                      child: Text(engine.locale('cultivationRank_$_rank')),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: fluent.FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop((_rank, _level));
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

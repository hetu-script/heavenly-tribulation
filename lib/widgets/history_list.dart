import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/pointer_detector.dart';

// import '../engine.dart';
import 'common.dart';
import '../state/history.dart';
import '../game/data.dart';

class HistoryList extends StatefulWidget {
  const HistoryList({
    super.key,
    required this.historyData,
  });

  final Iterable<dynamic> historyData;

  @override
  State<HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<HistoryList> {
  final _historyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  void jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _historyScrollController
          .jumpTo(_historyScrollController.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    super.dispose();

    _historyScrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];

    for (final id in widget.historyData) {
      final incident = GameData.history[id];
      assert(incident != null, 'Timeline incident not found: $id');
      widgets.add(Text(incident['message']));
    }

    jumpToBottom();

    return Container(
      padding: const EdgeInsets.all(10),
      height: MediaQuery.sizeOf(context).height - kTabBarHeight,
      child: ScrollConfiguration(
        behavior: MaterialScrollBehavior(),
        child: SingleChildScrollView(
          controller: _historyScrollController,
          child: ListView(
            shrinkWrap: true,
            children: widgets,
          ),
        ),
      ),
    );
  }
}

class HeroAndGlobalHistoryList extends StatefulWidget {
  HeroAndGlobalHistoryList({
    this.onTapUp,
    this.onMouseEnter,
    this.onMouseExit,
    this.limit = 2,
  }) : super(key: GlobalKey());

  final void Function()? onTapUp;
  final void Function(Rect rect)? onMouseEnter;
  final void Function()? onMouseExit;
  final int limit;

  @override
  State<HeroAndGlobalHistoryList> createState() =>
      _HeroAndGlobalHistoryListState();
}

class _HeroAndGlobalHistoryListState extends State<HeroAndGlobalHistoryList> {
  final _historyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  void jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _historyScrollController
          .jumpTo(_historyScrollController.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    super.dispose();

    _historyScrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incidents = context.watch<HeroAndGlobalHistoryState>().incidents;
    Iterable slice;
    if (incidents.length > widget.limit) {
      slice = incidents.skip(incidents.length - widget.limit);
    } else {
      slice = incidents;
    }

    jumpToBottom();

    return MouseRegion(
      onEnter: (event) {
        if (widget.onMouseEnter == null) return;

        final renderBox = context.findRenderObject() as RenderBox;
        final Size size = renderBox.size;
        final Offset offset = renderBox.localToGlobal(Offset.zero);
        final Rect rect =
            Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
        widget.onMouseEnter!.call(rect);
      },
      onExit: (event) {
        widget.onMouseExit?.call();
      },
      child: PointerDetector(
        // cursor: SystemMouseCursors.click,
        onTapUp: (_, __, ___) {
          widget.onTapUp?.call();
        },
        child: ScrollConfiguration(
          behavior: MaterialScrollBehavior(),
          child: SingleChildScrollView(
            controller: _historyScrollController,
            child: ListView(
              shrinkWrap: true,
              children: slice
                  .map((incident) => Text(
                        incident['message'],
                        style: TextStyle(
                          color: Colors.yellow,
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

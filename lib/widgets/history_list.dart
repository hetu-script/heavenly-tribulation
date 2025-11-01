import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/widgets/ui/mouse_region2.dart';

import '../ui.dart';
import 'common.dart';
import '../data/game.dart';
import '../state/game_state.dart';

class HistoryList extends StatefulWidget {
  const HistoryList({
    super.key,
    this.limit,
    required this.historyData,
    this.onTapUp,
    this.onMouseEnter,
    this.onMouseExit,
  });

  final int? limit;
  final Iterable<dynamic> historyData;
  final void Function()? onTapUp;
  final void Function(Rect rect)? onMouseEnter;
  final void Function()? onMouseExit;

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

    for (var i = 0; i < widget.historyData.length; ++i) {
      final id = widget.historyData.elementAt(i);
      final incident = GameData.history[id];
      assert(incident != null, 'Timeline incident not found: $id');
      widgets.add(Text(incident['message']));
      if (widget.limit != null && i >= widget.limit! - 1) {
        break;
      }
    }

    jumpToBottom();

    return MouseRegion2(
      cursor: widget.onTapUp != null
          ? GameUI.cursor.resolve({WidgetState.hovered})
          : GameUI.cursor.resolve({}),
      onEnter: (rect) {
        widget.onMouseEnter?.call(rect);
      },
      onExit: () {
        widget.onMouseExit?.call();
      },
      child: GestureDetector(
        onTapUp: (details) {
          widget.onTapUp?.call();
        },
        child: Container(
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
    this.limit = 5,
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
    final incidents = context.watch<GameState>().incidents;
    Iterable slice;
    if (incidents.length > widget.limit) {
      slice = incidents.skip(incidents.length - widget.limit);
    } else {
      slice = incidents;
    }

    jumpToBottom();

    return MouseRegion2(
      cursor: GameUI.cursor.resolve({WidgetState.hovered}),
      onEnter: (rect) {
        widget.onMouseEnter?.call(rect);
      },
      onExit: () {
        widget.onMouseExit?.call();
      },
      child: GestureDetector(
        onTapUp: (details) {
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
                          fontSize: 14,
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

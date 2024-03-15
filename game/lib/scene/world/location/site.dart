import 'package:flutter/material.dart';
// import 'package:samsara/samsara.dart';
import 'package:samsara/event.dart';
import 'package:samsara/console.dart';

import '../../../config.dart';
import 'site_drop_menu.dart';

import '../../hero_info.dart';

class SiteView extends StatefulWidget {
  static Future<void> show({
    required BuildContext context,
    dynamic siteData,
    String? image,
  }) {
    assert(image != null || siteData != null);
    return showDialog<int?>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) {
        return SiteView(
          siteData: siteData,
          background: image,
        );
      },
    );
  }

  SiteView({
    this.siteData,
    this.background,
  }) : super(key: UniqueKey());

  final dynamic siteData;
  final String? background;

  @override
  State<SiteView> createState() => _SiteViewState();
}

class _SiteViewState extends State<SiteView>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  void close() {
    Navigator.maybeOf(context)?.maybePop();
  }

  @override
  void initState() {
    super.initState();

    engine.addEventListener(
      'exit_site',
      EventHandler(
        widgetKey: widget.key!,
        handle: (eventId, args, scene) => close(),
      ),
    );
  }

  @override
  void dispose() {
    engine.removeEventListener(widget.key!);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final backgroundImage = widget.background ??
        widget.siteData?['background'] ??
        '${widget.siteData?['category']}.png';

    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          if (backgroundImage != null)
            SizedBox(
              height: GameConfig.screenSize.height,
              width: GameConfig.screenSize.width,
              child: Image(
                image: AssetImage('assets/images/$backgroundImage'),
                fit: BoxFit.cover,
              ),
            ),
          const Positioned(
            left: 0,
            top: 0,
            child: HeroInfoPanel(),
          ),
          if (GameConfig.isDebugMode)
            Positioned(
              right: 0,
              top: 0,
              child: SiteViewDropMenu(
                onSelected: (SiteViewDropMenuItems item) async {
                  switch (item) {
                    case SiteViewDropMenuItems.console:
                      showDialog(
                        context: context,
                        builder: (BuildContext context) => Console(
                          engine: engine,
                        ),
                      ).then((_) => setState(() {}));
                    case SiteViewDropMenuItems.quit:
                      close();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

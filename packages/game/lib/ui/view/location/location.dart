import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';
// import 'package:quiver/pattern.dart';
// import 'package:samsara/event.dart';

import '../../../global.dart';
import 'site_card.dart';
import '../../shared/close_button.dart';
import '../../shared/responsive_window.dart';

class LocationView extends StatefulWidget {
  final bool showSites;
  final String? locationId;
  final HTStruct? locationData;

  const LocationView({
    super.key,
    this.showSites = true,
    this.locationId,
    this.locationData,
  });

  @override
  State<LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView> {
  late final List<Tab> _tabs;
  late final HTStruct _locationData;
  final List<Widget> _siteCards = [];

  @override
  void initState() {
    _tabs = [
      if (widget.showSites)
        Tab(
          iconMargin: const EdgeInsets.all(5.0),
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.business),
              ),
              Text(engine.locale['site']),
            ],
          ),
        ),
      Tab(
        iconMargin: const EdgeInsets.all(5.0),
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(Icons.summarize),
            ),
            Text(engine.locale['information']),
          ],
        ),
      ),
      Tab(
        iconMargin: const EdgeInsets.all(5.0),
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(Icons.person),
            ),
            Text(engine.locale['character']),
          ],
        ),
      ),
    ];

    if (widget.locationData != null) {
      _locationData = widget.locationData!;
    } else {
      final locationId = widget.locationId ??
          ModalRoute.of(context)!.settings.arguments as String;
      _locationData =
          engine.invoke('getLocationById', positionalArgs: [locationId]);
    }

    final HTStruct sitesData = _locationData['sites'];
    final heroHomeId = engine.invoke('getHeroHomeLocationId');
    if (_locationData['id'] == heroHomeId) {
      final heroHomeSite = engine.invoke('getHeroHomeSite');
      _siteCards.add(
        SiteCard(
          siteData: heroHomeSite,
          imagePath: heroHomeSite['image'],
        ),
      );
    }

    _siteCards.addAll(sitesData.values.map(
      (siteData) {
        return SiteCard(
          siteData: siteData,
          imagePath: siteData['image'],
        );
      },
    ));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWindow(
      alignment: AlignmentDirectional.topStart,
      size: const Size(400.0, 400.0),
      child: DefaultTabController(
        length: _tabs.length, // 物品栏通过tabs过滤不同种类的物品
        child: Scaffold(
          backgroundColor: kBackgroundColor,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(_locationData['name']),
            actions: const [ButtonClose()],
            bottom: TabBar(
              tabs: _tabs,
            ),
          ),
          body: TabBarView(
            children: [
              if (widget.showSites)
                ListView(
                  shrinkWrap: true,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Wrap(
                          spacing: 8.0, // gap between adjacent chips
                          runSpacing: 4.0, // gap between lines
                          children: _siteCards,
                        ),
                      ),
                    ),
                  ],
                ),
              Container(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${engine.locale['worldPosition']}: ${_locationData['tilePosition']['left']}, ${_locationData['tilePosition']['top']}'),
                    // Text('${engine.locale['money']}: ${_locationData['money']}'),
                    Text(
                        '${engine.locale['development']}: ${_locationData['development']}'),
                    Text(
                        '${engine.locale['stability']}: ${_locationData['stability']}'),
                  ],
                ),
              ),
              Container(),
            ],
          ),
        ),
      ),
    );
  }
}

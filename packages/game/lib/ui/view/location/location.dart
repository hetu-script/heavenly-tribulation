import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../event/events.dart';
import '../../../engine/engine.dart';
import 'site_card.dart';

class LocationView extends StatefulWidget {
  const LocationView({required Key key}) : super(key: key);

  @override
  _LocationViewState createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final locationId = ModalRoute.of(context)!.settings.arguments as String;

    final data =
        engine.hetu.invoke('getLocationById', positionalArgs: [locationId]);

    String? locationName = data['name'];
    if (locationName == null) {
      final String nameId = data['nameId'];
      locationName = engine.locale[nameId];
    }
    final locationImagePath = data['image'];
    // _leadershipName = widget.locationData['leadershipName'];

    final HTStruct sitesData = data['sites'];

    final siteCards = sitesData.values.map((siteData) {
      final String locationId = siteData['locationId'];
      final String siteId = siteData['category'];
      final title = siteData['name'];
      String? imagePath = siteData['image'];
      return SiteCard(
        locationId: locationId,
        siteId: siteId,
        title: title,
        imagePath: imagePath,
      );
    }).toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200.0),
        child: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              engine.broadcast(LocationEvent.left(locationId: locationId));
              Navigator.of(context).pop();
            },
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              image: locationImagePath != null
                  ? DecorationImage(
                      image: AssetImage('assets/images/$locationImagePath'),
                      fit: BoxFit.fill,
                    )
                  : null,
            ),
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.fromLTRB(70, 10, 10, 10),
              child: SizedBox(
                width: 180.0,
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          locationName,
                          style: const TextStyle(fontSize: 24.0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // bottom: ColoredPreferredSizeWidget(
          //   backgroundColor: Colors.transparent.withOpacity(0.5),
          //   child: TabBar(
          //     controller: _tabController,
          //     tabs: _tabs,
          //     unselectedLabelStyle: const TextStyle(fontSize: 16.0),
          //     labelStyle: const TextStyle(fontSize: 20.0),
          //   ),
          // ),
        ),
      ),
      body: RefreshIndicator(
        // key: _refreshIndicatorKey,
        onRefresh: () async {
          setState(() {});
        },
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            },
          ),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            shrinkWrap: true,
            children: <Widget>[
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Wrap(
                    spacing: 8.0, // gap between adjacent chips
                    runSpacing: 4.0, // gap between lines
                    children: siteCards,
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

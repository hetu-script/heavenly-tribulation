import 'dart:ui';

import 'package:flutter/material.dart';

import '../empty_placeholder.dart';
import '../../engine/game.dart';
// import '../colored_widget.dart';

class LocationView extends StatefulWidget {
  final SamsaraGame game;

  final String locationId;

  const LocationView({
    required this.game,
    required this.locationId,
    Key? key,
  }) : super(key: key);

  @override
  _LocationViewState createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  SamsaraGame get game => widget.game;

  // final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  List<Widget>? _sceneCards;

  // static const _tabs = <Tab>[
  //   Tab(text: '动态'),
  //   Tab(text: '场景'),
  // ];

  // late TabController _tabController;
  late String _locationName,
      // _leadershipName,
      // _organization,
      // _organizationName,
      _locationImage;

  Future<void> updateData() async {
    game.hetu.invoke('nextTick');

    final data = game.hetu
        .invoke('getLocationDataById', positionalArgs: [widget.locationId]);

    setState(() {
      final String nameId = data['name'];
      _locationName = game.texts[nameId];
      _locationImage = data['image'];
      // _leadershipName = widget.locationData['leadershipName'];

      final Map<String, dynamic>? scenesData = data['scenes'];

      _sceneCards = scenesData?.values.map((value) {
        final sceneData = value as Map<String, dynamic>;
        final String id = sceneData['id'];
        final String type = sceneData['type'];
        final titleId = sceneData['name'];
        String title;
        if (titleId == null) {
          title = _getDefaultTitle(type);
        } else {
          title = game.texts[titleId];
        }
        String? image = sceneData['image'];
        image ??= _getDefaultImagePath(type);

        return SizedBox(
          width: 210,
          height: 150,
          child: Card(
            elevation: 8.0,
            shadowColor: Colors.black26,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                image: DecorationImage(
                  image: AssetImage('assets/images/$image'),
                  fit: BoxFit.cover,
                ),
              ),
              child: InkWell(
                splashColor: Colors.blue.withAlpha(30),
                onTap: () {
                  game.hetu
                      .invoke('handleSceneInteraction', positionalArgs: [id]);
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        color: Colors.white.withOpacity(0.5),
                        child: Text(title),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false);
    });
  }

  @override
  void initState() {
    super.initState();
    // _tabController = TabController(vsync: this, length: _tabs.length);
    updateData();
  }

  @override
  void dispose() {
    // _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200.0),
        child: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/$_locationImage'),
                fit: BoxFit.cover,
              ),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 180.0,
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0)),
                  color: Colors.white.withOpacity(0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _locationName,
                          style: const TextStyle(
                            fontSize: 24.0,
                          ),
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
        onRefresh: updateData,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            },
          ),
          child: Scrollbar(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              shrinkWrap: true,
              children: <Widget>[
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: (_sceneCards != null && _sceneCards!.isNotEmpty)
                        ? Wrap(
                            spacing: 8.0, // gap between adjacent chips
                            runSpacing: 4.0, // gap between lines
                            children: _sceneCards!)
                        : EmptyPlaceholder(text: game.texts['generic.empty']),
                  ),
                ),
              ],
            ),
          ),
        ),
        // TabBarView(
        //   controller: _tabController,
        //   children: _pages,
        // )
      ),
    );
  }
}

String _getDefaultTitle(String type) {
  String title;
  switch (type) {
    case 'headquarters':
      title = 'scenes.headquarters';
      break;
    case 'residency':
      title = 'scenes.residency';
      break;
    case 'library':
      title = 'scenes.library';
      break;
    case 'farmland':
      title = 'scenes.farmland';
      break;
    case 'mine':
      title = 'scenes.mine';
      break;
    case 'timberland':
      title = 'scenes.timberland';
      break;
    case 'market':
      title = 'scenes.market';
      break;
    case 'shop':
      title = 'scenes.shop';
      break;
    case 'restaurant':
      title = 'scenes.restaurant';
      break;
    case 'arena':
      title = 'scenes.arena';
      break;
    case 'nursery':
      title = 'scenes.nursery';
      break;
    case 'workshop':
      title = 'scenes.workshop';
      break;
    case 'alchemylab':
      title = 'scenes.alchemylab';
      break;
    case 'smithshop':
      title = 'scenes.smithshop';
      break;
    case 'zenroom':
      title = 'scenes.zenroom';
      break;
    case 'zoo':
      title = 'scenes.zoo';
      break;
    case 'maze':
      title = 'scenes.maze';
      break;
    default:
      title = 'generic.missing';
  }
  return title;
}

String _getDefaultImagePath(String type) {
  String imagePath;
  switch (type) {
    case 'headquarters':
      imagePath = 'location/scene/scene.headquarters.png';
      break;
    case 'residency':
      imagePath = 'location/scene/scene.residency.png';
      break;
    case 'library':
      imagePath = 'location/scene/scene.library.png';
      break;
    case 'farmland':
      imagePath = 'location/scene/scene.farmland.png';
      break;
    case 'mine':
      imagePath = 'location/scene/scene.mine.png';
      break;
    case 'timberland':
      imagePath = 'location/scene/scene.timberland.png';
      break;
    case 'market':
      imagePath = '/location/scene/scene.market.png';
      break;
    case 'shop':
      imagePath = 'location/scene/scene.shop.png';
      break;
    case 'restaurant':
      imagePath = 'location/scene/scene.restaurant.png';
      break;
    case 'arena':
      imagePath = 'location/scene/scene.arena.png';
      break;
    case 'nursery':
      imagePath = 'location/scene/scene.nursery.png';
      break;
    case 'workshop':
      imagePath = 'location/scene/scene.workshop.png';
      break;
    case 'alchemylab':
      imagePath = 'location/scene/scene.alchemylab.png';
      break;
    case 'smithshop':
      imagePath = 'location/scene/scene.smithshop.png';
      break;
    case 'zenroom':
      imagePath = 'location/scene/scene.zenroom.png';
      break;
    case 'zoo':
      imagePath = 'location/scene/scene.zoo.png';
      break;
    case 'maze':
      imagePath = 'location/scene/scene.maze.png';
      break;
    default:
      imagePath = 'location/scene/asset_missing.png';
  }
  return imagePath;
}

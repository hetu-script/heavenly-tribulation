import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';

import '../../../../engine/tilemap/map.dart';
import '../../../../event/event.dart';
import '../../shared/pointer_detector.dart';
import '../../../../engine/engine.dart';
import '../../../../engine/scene/worldmap.dart';
import '../../shared/avatar.dart';
import '../../../../event/map_event.dart';
import 'popup.dart';
import 'location_brief.dart';

// This is the type used by the popup menu below.
enum TopMenuItems { showNations, exit }

class WorldMapOverlay extends StatefulWidget {
  final WorldMapScene scene;

  const WorldMapOverlay({required Key key, required this.scene})
      : super(key: key);

  @override
  _WorldMapOverlayState createState() => _WorldMapOverlayState();
}

class _WorldMapOverlayState extends State<WorldMapOverlay> {
  WorldMapScene get scene => widget.scene;
  MapComponent get map => widget.scene.map!;

  Vector2? menuPosition;

  @override
  void initState() {
    super.initState();

    Flame.images.load('character/tile_character.png').then((image) {
      setState(() {});
    });

    engine.registerListener(
      MapEvents.onMapLoaded,
      EventHandler(widget.key!, (event) {
        setState(() {});
      }),
    );

    engine.registerListener(
      MapEvents.onMapTapped,
      EventHandler(widget.key!, (event) {
        if (map.hero!.isMoving) {
          return;
        }
        setState(() {
          final e = event as MapInteractionEvent;
          if (e.terrain != null) {
            final tilePos = e.terrain!.tilePosition;
            menuPosition = scene.map!
                .tilePosition2TileCenterInScreen(tilePos.left, tilePos.top);
          }
        });
      }),
    );
  }

  @override
  void dispose() {
    super.dispose();
    engine.disposeListenders(widget.key!);
  }

  @override
  Widget build(BuildContext context) {
    final heroData = engine.hetu.invoke('getCurrentCharacter');
    final screenSize = MediaQuery.of(context).size;

    final heroInfoRow = <Widget>[];
    if (heroData != null) {
      heroInfoRow.add(
        Avatar(
          avatarAssetKey: 'assets/images/${heroData['avatar']}',
          size: 100,
        ),
      );
    }

    final screenWidgets = <Widget>[
      SizedBox(
        height: screenSize.height,
        width: screenSize.width,
        child: PointerDetector(
          child: GameWidget(
            game: scene,
          ),
          onTapDown: scene.onTapDown,
          onTapUp: scene.onTapUp,
          onDragStart: scene.onDragStart,
          onDragUpdate: scene.onDragUpdate,
          onDragEnd: scene.onDragEnd,
          onScaleStart: scene.onScaleStart,
          onScaleUpdate: scene.onScaleUpdate,
          onScaleEnd: scene.onScaleEnd,
          onLongPress: scene.onLongPress,
          onMouseMove: scene.onMouseMove,
        ),
      ),
      Positioned(
        left: 0,
        top: 0,
        child: Container(
          height: 120,
          width: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                const BorderRadius.only(bottomRight: Radius.circular(5.0)),
            border: Border.all(
              width: 2,
              color: Colors.lightBlue.withOpacity(0.5),
            ),
          ),
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: heroInfoRow,
          ),
        ),
      ),
      Positioned(
        right: 0,
        top: 0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                const BorderRadius.only(bottomLeft: Radius.circular(5.0)),
            border: Border.all(
              width: 2,
              color: Colors.lightBlue.withOpacity(0.5),
            ),
          ),
          child: PopupMenuButton<TopMenuItems>(
            offset: const Offset(0, 45),
            icon: const Icon(Icons.menu_open),
            onSelected: (TopMenuItems item) {
              if (item == TopMenuItems.showNations) {
                map.showNations = !map.showNations;
              }
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<TopMenuItems>>[
              CheckedPopupMenuItem<TopMenuItems>(
                value: TopMenuItems.showNations,
                checked: map.showNations,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(engine.locale['showNations']),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<TopMenuItems>(
                padding: const EdgeInsets.only(right: 34),
                value: TopMenuItems.exit,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(engine.locale['exitGame']),
                ),
                onTap: () {
                  engine.leaveScene('WorldMap');
                },
              ),
            ],
          ),
        ),
      ),
    ];

    if (menuPosition != null) {
      if (map.selectedTerrain != null) {
        final terrain = map.selectedTerrain!;
        final terrainZone = map.zones[terrain.zoneIndex];
        final characters = map.selectedActors;
        final hero = map.hero;
        List<int>? route;
        var isHeroPosition = false;
        if (terrain.tilePosition != hero!.tilePosition) {
          final start = engine.hetu
              .invoke('getTerrain', positionalArgs: [hero.left, hero.top]);
          final end = engine.hetu.invoke('getTerrain',
              positionalArgs: [terrain.left, terrain.top]);
          List? calculatedRoute = engine.hetu
              .invoke('calculateRoute', positionalArgs: [start, end]);
          if (calculatedRoute != null) {
            route = List<int>.from(calculatedRoute);
            // for (var i = 1; i < route.length; ++i) {
            //   final index = route[i];
            //   final tilePosition = map.index2TilePos(index);
            //   print(tilePosition);
            // }
          }
        } else {
          isHeroPosition = true;
        }

        void closePopup() {
          setState(() {
            menuPosition = null;
            scene.map!.selectedTerrain = null;
          });
        }

        final stringBuffer = StringBuffer();

        final zoneData = engine.hetu
            .invoke('getZoneByIndex', positionalArgs: [terrain.zoneIndex]);
        stringBuffer
            .writeln('${zoneData['name']}(${terrain.left}, ${terrain.top})');

        if (terrain.nationId != null) {
          final nationData = engine.hetu
              .invoke('getNationById', positionalArgs: [terrain.nationId]);
          stringBuffer.writeln('${nationData['name']}');
        }

        if (terrain.locationId != null) {
          final locationData = engine.hetu
              .invoke('getLocationById', positionalArgs: [terrain.locationId]);
          stringBuffer.writeln('${locationData['name']}');
        }

        screenWidgets.add(
          WorldMapPopup(
            left: menuPosition!.x - WorldMapPopup.defaultSize / 2,
            top: menuPosition!.y - WorldMapPopup.defaultSize / 2,
            onPanelTapped: closePopup,
            moveToIcon: route != null,
            onMoveToIconTapped: () {
              map.moveHeroToTilePositionByRoute(route!);
              closePopup();
            },
            checkIcon: terrainZone.index != 0,
            onCheckIconTapped: () {
              LocationBrief.show(context,
                  terrain: map.selectedTerrain, isHeroPosition: isHeroPosition);
              closePopup();
            },
            enterIcon: ((route != null && terrain.locationId != null) ||
                    (isHeroPosition && terrain.locationId != null))
                ? true
                : false,
            onEnterIconTapped: closePopup,
            talkIcon: characters != null ? true : false,
            onTalkIconTapped: closePopup,
            restIcon: isHeroPosition,
            onRestIconTapped: closePopup,
            title: stringBuffer.toString(),
          ),
        );
      }
    }

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: screenSize.height,
        width: screenSize.width,
        child: Stack(
          children: screenWidgets,
        ),
      ),
    );
  }
}

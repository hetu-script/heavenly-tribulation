import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/hover_info.dart';

import '../global.dart';
import '../data/game.dart';

void previewCard(
  BuildContext context,
  String id,
  dynamic cardData,
  Rect rect, {
  bool isLibrary = true,
  HoverContentDirection? direction,
  dynamic character,
}) {
  context.read<HoverContentState>().show(
        buildItemHoverInfo(
          cardData,
          type: isLibrary ? ItemType.player : ItemType.none,
        ),
        rect,
        direction: direction ?? HoverContentDirection.rightTop,
      );
}

void unpreviewCard(BuildContext context) {
  context.read<HoverContentState>().hide();
}

enum InformationViewMode {
  view,
  select,
  manage,
  edit,
}

const kTabBarHeight = 72.0;
const kNestedTabBarHeight = 178.0;

const kToolbarTabBarHeight = 30.0;

const kDefaultItemGridSize = Size(48.0, 48.0);

const kEntityTableCharacterColumns = {
  'name': 100.0,
  'gender': 50.0,
  'age': 50.0,
  'level2': 50.0,
  'rank': 80.0,
  'fame': 50.0,
  'home': 100.0,
  'sect': 100.0,
  'title': 80.0,
};

const kEntityTableMemberColumns = {
  'name': 100.0,
  'gender': 50.0,
  'age': 50.0,
  'level': 50.0,
  'rank': 80.0,
  'jobTitle': 80.0,
  'contribution': 60.0,
  'superior': 100.0,
  'reportCity': 100.0,
};

const kEntityTableLocationColumns = {
  'name': 100.0,
  'position': 120.0,
  'kind': 80.0,
  'development': 50.0,
  'residents': 60.0,
  'sect': 100.0,
  'manager': 100.0,
};

const kEntityTableSiteColumns = {
  'name': 100.0,
  'position': 100.0,
  'kind': 80.0,
  'development': 50.0,
  'sect': 100.0,
  'manager': 100.0,
};

const kEntityTableSectColumns = {
  'name': 100.0,
  'head': 100.0,
  'category': 80.0,
  'genre': 80.0,
  'headquarters': 100.0,
  'cityNumber': 60.0,
  'memberNumber': 60.0,
  'recruitMonth': 50.0,
};

enum ItemType {
  none,
  player,
  npc,
  customer,
  merchant,
}

String? buildItemHoverInfo(
  dynamic data, {
  dynamic priceFactor,
  ItemType type = ItemType.none,
  bool isDetailed = false,
}) {
  switch (data['entityType']) {
    case 'item':
      String description;
      switch (type) {
        case ItemType.none:
        case ItemType.npc:
          description = GameData.getItemDescription(
            data,
            isDetailed: isDetailed,
          );
        case ItemType.player:
          description = GameData.getItemDescription(
            data,
            isInventory: true,
            isDetailed: isDetailed,
          );
        case ItemType.customer:
          description = GameData.getItemDescription(
            data,
            priceFactor: priceFactor,
            isSell: true,
            isDetailed: isDetailed,
          );
        case ItemType.merchant:
          description = GameData.getItemDescription(
            data,
            priceFactor: priceFactor,
            isSell: false,
            isDetailed: isDetailed,
          );
      }
      return description;
    case 'battle_card':
      final (_, description) = GameData.getBattleCardDescription(
        showRequirement: type == ItemType.player,
        data,
        isDetailed: isDetailed,
        showDebugId: engine.config.debugMode,
      );
      return description;
  }

  return null;
}

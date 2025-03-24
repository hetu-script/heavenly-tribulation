import 'package:flutter/material.dart';

import '../../engine.dart';
import '../../widgets/menu_item_builder.dart';

enum OrderByOptions {
  byAcquiredTimeDescending,
  byAcquiredTimeAscending,
  byLevelDescending,
  byLevelAscending,
  byRankDescending,
  byRankAscending,
}

List<PopupMenuEntry<OrderByOptions>> buildOrderByMenuItems(
    {void Function(OrderByOptions option)? onSelectedItem}) {
  return <PopupMenuEntry<OrderByOptions>>[
    buildSubMenuItem(
      items: {
        engine.locale('descending'): OrderByOptions.byAcquiredTimeDescending,
        engine.locale('ascending'): OrderByOptions.byAcquiredTimeAscending,
      },
      width: 90,
      name: engine.locale('acquiredTime'),
      onSelectedItem: onSelectedItem,
    ),
    buildSubMenuItem(
      items: {
        engine.locale('descending'): OrderByOptions.byLevelDescending,
        engine.locale('ascending'): OrderByOptions.byLevelAscending,
      },
      width: 90,
      name: engine.locale('level'),
      onSelectedItem: onSelectedItem,
    ),
    buildSubMenuItem(
      items: {
        engine.locale('descending'): OrderByOptions.byRankDescending,
        engine.locale('ascending'): OrderByOptions.byRankAscending,
      },
      width: 90,
      name: engine.locale('cultivationRank'),
      onSelectedItem: onSelectedItem,
    ),
  ];
}

enum DeckMenuItems {
  setAsBattleDeck,
  editDeck,
  deleteDeck,
}

List<PopupMenuEntry<DeckMenuItems>> buildDeckPopUpMenuItems(
    {void Function(DeckMenuItems item)? onSelectedItem}) {
  return <PopupMenuEntry<DeckMenuItems>>[
    buildMenuItem(
      item: DeckMenuItems.setAsBattleDeck,
      name: engine.locale('deckbuilding_set_battle_deck'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: DeckMenuItems.editDeck,
      name: engine.locale('edit'),
      onSelectedItem: onSelectedItem,
    ),
    const PopupMenuDivider(height: 12.0),
    buildMenuItem(
      item: DeckMenuItems.deleteDeck,
      name: engine.locale('delete'),
      onSelectedItem: onSelectedItem,
    ),
  ];
}

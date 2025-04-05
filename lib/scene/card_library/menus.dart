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

enum FilterByOptions {
  all,
  requirementsMet,
  categoryAttack,
  categoryBuff,
  spellcraft,
  swordcraft,
  avatar,
  bodyforge,
  vitality,
  kind_punch,
  kind_kick,
  kind_qinna,
  kind_dianxue,
  kind_sword,
  kind_sabre,
  kind_staff,
  kind_spear,
  kind_bow,
  kind_dart,
  kind_flying_sword,
  kind_shenfa,
  kind_qinggong,
  kind_xinfa,
  kind_airbend,
  kind_firebend,
  kind_waterbend,
  kind_lightning_control,
  kind_earthbend,
  kind_plant_control,
  kind_sigil,
  kind_power_word,
  kind_scripture,
  kind_music,
  kind_array,
  kind_potion,
  kind_scroll,
}

List<PopupMenuEntry<FilterByOptions>> buildFilterByMenuItems(
    {void Function(FilterByOptions option)? onSelectedItem}) {
  return <PopupMenuEntry<FilterByOptions>>[
    buildMenuItem(
      item: FilterByOptions.all,
      name: engine.locale('all'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: FilterByOptions.requirementsMet,
      name: engine.locale('requirementsMet'),
      onSelectedItem: onSelectedItem,
    ),
    buildSubMenuItem(
      items: {
        engine.locale('attack'): FilterByOptions.categoryAttack,
        engine.locale('buff'): FilterByOptions.categoryBuff,
      },
      width: 90,
      name: engine.locale('category'),
      onSelectedItem: onSelectedItem,
    ),
    buildSubMenuItem(
      items: {
        engine.locale('spellcraft'): FilterByOptions.spellcraft,
        engine.locale('swordcraft'): FilterByOptions.swordcraft,
        engine.locale('bodyforge'): FilterByOptions.bodyforge,
        engine.locale('avatar'): FilterByOptions.avatar,
        engine.locale('vitality'): FilterByOptions.vitality,
      },
      width: 90,
      name: engine.locale('genre'),
      onSelectedItem: onSelectedItem,
    ),
    buildSubMenuItem(
      items: {
        engine.locale('kind_punch'): FilterByOptions.kind_punch,
        engine.locale('kind_kick'): FilterByOptions.kind_kick,
        engine.locale('kind_qinna'): FilterByOptions.kind_qinna,
        engine.locale('kind_dianxue'): FilterByOptions.kind_dianxue,
        engine.locale('kind_sword'): FilterByOptions.kind_sword,
        engine.locale('kind_sabre'): FilterByOptions.kind_sabre,
        engine.locale('kind_staff'): FilterByOptions.kind_staff,
        engine.locale('kind_spear'): FilterByOptions.kind_spear,
        engine.locale('kind_bow'): FilterByOptions.kind_bow,
        engine.locale('kind_dart'): FilterByOptions.kind_dart,
        engine.locale('kind_shenfa'): FilterByOptions.kind_shenfa,
        engine.locale('kind_qinggong'): FilterByOptions.kind_qinggong,
        engine.locale('kind_xinfa'): FilterByOptions.kind_xinfa,
      },
      width: 90,
      name: engine.locale('martialArts'),
      onSelectedItem: onSelectedItem,
    ),
    buildSubMenuItem(
      items: {
        engine.locale('kind_flying_sword'): FilterByOptions.kind_flying_sword,
        engine.locale('kind_airbend'): FilterByOptions.kind_airbend,
        engine.locale('kind_firebend'): FilterByOptions.kind_firebend,
        engine.locale('kind_waterbend'): FilterByOptions.kind_waterbend,
        engine.locale('kind_lightning_control'):
            FilterByOptions.kind_lightning_control,
        engine.locale('kind_earthbend'): FilterByOptions.kind_earthbend,
        engine.locale('kind_plant_control'): FilterByOptions.kind_plant_control,
      },
      width: 90,
      name: engine.locale('sorcery'),
      onSelectedItem: onSelectedItem,
    ),
    buildSubMenuItem(
      items: {
        engine.locale('kind_sigil'): FilterByOptions.kind_sigil,
        engine.locale('kind_power_word'): FilterByOptions.kind_power_word,
        engine.locale('kind_scripture'): FilterByOptions.kind_scripture,
        engine.locale('kind_music'): FilterByOptions.kind_music,
        engine.locale('kind_array'): FilterByOptions.kind_array,
        engine.locale('kind_potion'): FilterByOptions.kind_potion,
        engine.locale('kind_scroll'): FilterByOptions.kind_scroll,
      },
      width: 90,
      name: engine.locale('other'),
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

import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:samsara/ui/close_button2.dart';
import 'package:provider/provider.dart';

import '../../engine.dart';
import 'inventory/inventory.dart';
import '../../game/data.dart';
import '../../state/hoverinfo.dart';
import '../../state/character.dart';
import '../../scene/game_dialog/game_dialog_content.dart';

class MerchantDialog extends StatefulWidget {
  const MerchantDialog({
    super.key,
    required this.merchantData,
    this.useShards = false,
    required this.priceFactor,
    this.filter,
  });

  final dynamic merchantData;

  final bool useShards;

  /// 交易物品时，需要支付的价格相比商品基础价格的乘数
  /// key为`base`, `sell`, category、kind 或 id，value 为价格乘数
  /// category，kind 和 id 分开保存，叠加计算
  /// 购买和出售有单独的影响因子
  /// {
  ///   useShard: true,
  ///   base: 1.0,
  ///   sell: 0.3,
  ///   category: {
  ///     weapon: 1.0,
  ///   },
  ///   kind: {
  ///     sword: 1.0,
  ///   },
  ///   id: {
  ///     'sword1': 1.0,
  ///   },
  /// }
  /// 将所有匹配的乘数乘在一起，然后再乘以物品本身的price
  final dynamic priceFactor;

  /// key 可能是 `category`、`kind`、`id`、`isIdentified`
  /// value 为具体的category、kind 或 id
  final dynamic filter;

  @override
  State<MerchantDialog> createState() => _MerchantDialogState();
}

class _MerchantDialogState extends State<MerchantDialog> {
  final Map<String, dynamic> _selectedHeroItemsData = {},
      _selectedMerchantItemsData = {};

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      width: 720.0,
      height: 500.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('trade')),
          actions: [
            CloseButton2(
              onPressed: () {
                context.read<MerchantState>().close();
              },
            )
          ],
        ),
        body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(GameData.heroData['name']),
                    Container(
                      width: 320.0,
                      height: 350,
                      margin: const EdgeInsets.only(top: 10.0),
                      child: Inventory(
                        height: 350,
                        characterData: GameData.heroData,
                        type: HoverType.customer,
                        priceFactor: widget.priceFactor,
                        selectedItemId: _selectedHeroItemsData.keys,
                        onTapped: (itemData, screenPosition) {
                          if (_selectedHeroItemsData
                              .containsKey(itemData['id'])) {
                            _selectedHeroItemsData.remove(itemData['id']);
                          } else {
                            _selectedHeroItemsData[itemData['id']] = itemData;
                          }
                          setState(() {});
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          final items = _selectedHeroItemsData.values.toList();
                          if (items.isEmpty) return;

                          int totalPrice = 0;
                          for (final itemData in items) {
                            totalPrice += GameData.calculateItemPrice(
                              itemData,
                              priceFactor: widget.priceFactor,
                              isSell: true,
                            );
                          }
                          if (widget.useShards) {
                            engine.hetu.invoke(
                              'collect',
                              namespace: 'Player',
                              positionalArgs: ['shard'],
                              namedArgs: {'amount': totalPrice},
                            );
                          } else {
                            engine.hetu.invoke(
                              'collect',
                              namespace: 'Player',
                              positionalArgs: ['money'],
                              namedArgs: {'amount': totalPrice},
                            );
                          }
                          engine.play('coins-31879.mp3');

                          for (final itemData in items) {
                            engine.hetu.invoke('entityLose', positionalArgs: [
                              GameData.heroData,
                              itemData,
                            ]);
                            engine.hetu
                                .invoke('entityAcquire', positionalArgs: [
                              widget.merchantData,
                              itemData,
                            ]);
                            _selectedHeroItemsData.remove(itemData['id']);
                            setState(() {});
                          }
                        },
                        child: Text(engine.locale('sell')),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(widget.merchantData['name']),
                    Container(
                      width: 320.0,
                      height: 350,
                      margin: const EdgeInsets.only(top: 10.0),
                      child: Inventory(
                        height: 350,
                        characterData: widget.merchantData,
                        type: HoverType.merchant,
                        priceFactor: widget.priceFactor,
                        selectedItemId: _selectedMerchantItemsData.keys,
                        onTapped: (itemData, screenPosition) {
                          if (_selectedMerchantItemsData
                              .containsKey(itemData['id'])) {
                            _selectedMerchantItemsData.remove(itemData['id']);
                          } else {
                            _selectedMerchantItemsData[itemData['id']] =
                                itemData;
                          }
                          setState(() {});
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          final items =
                              _selectedMerchantItemsData.values.toList();
                          if (items.isEmpty) return;

                          int totalPrice = 0;
                          for (final itemData in items) {
                            totalPrice += GameData.calculateItemPrice(
                              itemData,
                              priceFactor: widget.priceFactor,
                            );
                          }
                          if (widget.useShards) {
                            int shards =
                                GameData.heroData['materials']['shard'];
                            if (shards < totalPrice) {
                              GameDialogContent.show(
                                  context, 'hint_notEnoughShards');
                              return;
                            }
                            engine.hetu.invoke(
                              'exhaust',
                              namespace: 'Player',
                              positionalArgs: ['shard'],
                              namedArgs: {'amount': totalPrice},
                            );
                          } else {
                            int money = GameData.heroData['materials']['money'];
                            if (money < totalPrice) {
                              GameDialogContent.show(
                                  context, 'hint_notEnoughMoney');
                              return;
                            }
                            engine.hetu.invoke(
                              'exhaust',
                              namespace: 'Player',
                              positionalArgs: ['money'],
                              namedArgs: {'amount': totalPrice},
                            );
                          }
                          engine.play('pickup_item-64282.mp3');

                          for (final itemData in items) {
                            engine.hetu.invoke('entityLose', positionalArgs: [
                              widget.merchantData,
                              itemData,
                            ]);
                            engine.hetu
                                .invoke('entityAcquire', positionalArgs: [
                              GameData.heroData,
                              itemData,
                            ]);
                            _selectedMerchantItemsData.remove(itemData['id']);
                            setState(() {});
                          }
                        },
                        child: Text(engine.locale('buy')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

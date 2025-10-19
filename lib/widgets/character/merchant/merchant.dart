import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:samsara/widgets/ui/responsive_view.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../../ui.dart';
import '../../../game/logic/logic.dart';
import '../../../engine.dart';
import '../inventory/inventory.dart';
import '../../../game/game.dart';
import '../../../state/character.dart';
import '../../../scene/game_dialog/game_dialog_content.dart';
import 'material_bar.dart';
import '../inventory/material.dart';
import '../../dialog/input_slider.dart';
import '../../ui/close_button2.dart';

class MerchantDialog extends StatefulWidget {
  const MerchantDialog({
    super.key,
    required this.merchantData,
    this.useShard = false,
    this.materialMode = false,
    required this.priceFactor,
    this.filter,
    this.merchantType = MerchantType.none,
  });

  final dynamic merchantData;
  final bool useShard;
  final bool materialMode;

  /// 交易物品时，需要支付的价格相比商品基础价格的乘数
  /// key为`base`, `sell`, category、kind 或 id，value 为价格乘数
  /// category，kind 和 id 分开保存，叠加计算
  /// 出售有单独的影响因子
  /// {
  ///   useShard: true,
  ///   base: 1.0,
  ///   sell: 0.5,
  ///   category: {
  ///     weapon: 1.0,
  ///   },
  ///   kind: {
  ///     sword: 1.0,
  ///   },
  /// }
  /// 将所有匹配的乘数乘在一起，然后再乘以物品本身的price
  final dynamic priceFactor;

  /// key 可能是 `category`、`kind`、`id`、`isIdentified`
  /// value 为具体的category、kind 或 id
  final dynamic filter;

  final MerchantType merchantType;

  @override
  State<MerchantDialog> createState() => _MerchantDialogState();
}

class _MerchantDialogState extends State<MerchantDialog> {
  final Map<String, dynamic> _selectedHeroItemsData = {},
      _selectedMerchantItemsData = {};

  String? _selectedHeroMaterialId, _selectedMerchantMaterialId;

  dynamic priceFactor;

  bool get isDepositBox => widget.merchantType == MerchantType.depositBox;

  @override
  void initState() {
    super.initState();

    priceFactor = widget.priceFactor ?? {};
    priceFactor['useShard'] = widget.useShard;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      barrierColor: GameUI.backgroundColor,
      width: 720.0,
      height: 500.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale(isDepositBox ? 'exchange' : 'trade')),
          actions: [
            CloseButton2(
              onPressed: () {
                context.read<MerchantState>().close();
              },
            )
          ],
        ),
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(GameData.hero['name']),
                      if (!isDepositBox) CurrencyBar(entity: GameData.hero),
                      if (widget.materialMode)
                        MaterialList(
                          entity: GameData.hero,
                          height: 312.0,
                          priceFactor: priceFactor,
                          materialListType: isDepositBox
                              ? MaterialListType.inventory
                              : MaterialListType.sell,
                          selectedItem: _selectedHeroMaterialId,
                          onSelectedItem: (item) {
                            setState(() {
                              _selectedHeroMaterialId = item;
                            });
                          },
                        )
                      else
                        Container(
                          width: 300.0,
                          height: 312.0,
                          margin: const EdgeInsets.only(top: 10.0),
                          child: Inventory(
                            height: 350,
                            character: GameData.hero,
                            itemType: isDepositBox
                                ? ItemType.none
                                : ItemType.customer,
                            priceFactor: priceFactor,
                            selectedItemId: _selectedHeroItemsData.keys,
                            onItemTapped: (itemData, screenPosition) {
                              if (_selectedHeroItemsData
                                  .containsKey(itemData['id'])) {
                                _selectedHeroItemsData.remove(itemData['id']);
                              } else {
                                _selectedHeroItemsData[itemData['id']] =
                                    itemData;
                              }
                              setState(() {});
                            },
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0, bottom: 20.0),
                        child: fluent.FilledButton(
                          onPressed: () async {
                            int merchantMoney =
                                widget.merchantData['materials']['money'] ?? 0;
                            int merchantShard =
                                widget.merchantData['materials']['shard'] ?? 0;
                            if (widget.materialMode) {
                              if (_selectedHeroMaterialId == null) return;
                              final int max = GameData.hero['materials']
                                  [_selectedHeroMaterialId];

                              final int unitPrice =
                                  GameLogic.calculateMaterialPrice(
                                _selectedHeroMaterialId!,
                                priceFactor: priceFactor,
                                isSell: true,
                              );

                              final amount = await InputSliderDialog.show(
                                context: context,
                                min: 1,
                                max: max,
                                value: max,
                                labelBuilder: (value) {
                                  String label =
                                      '${engine.locale('amount')}: $value';
                                  if (!isDepositBox) {
                                    label +=
                                        '\n${engine.locale('totalPrice')}: ${unitPrice * value}';
                                  }
                                  return label;
                                },
                              );

                              if (amount == null) return;

                              if (!isDepositBox) {
                                final totalPrice = unitPrice * amount;

                                if (widget.useShard) {
                                  if (merchantShard < totalPrice) {
                                    GameDialogContent.show(
                                        context,
                                        engine.locale(
                                            'hint_merchantNotEnoughShard'));
                                    return;
                                  }
                                  engine.hetu.invoke(
                                    'entityExhaust',
                                    positionalArgs: [
                                      widget.merchantData,
                                      'shard',
                                      totalPrice,
                                    ],
                                  );
                                  engine.hetu.invoke(
                                    'collect',
                                    namespace: 'Player',
                                    positionalArgs: ['shard', totalPrice],
                                  );
                                } else {
                                  if (merchantMoney < totalPrice) {
                                    GameDialogContent.show(
                                        context,
                                        engine.locale(
                                            'hint_merchantNotEnoughMoney'));
                                    return;
                                  }
                                  engine.hetu.invoke(
                                    'entityExhaust',
                                    positionalArgs: [
                                      widget.merchantData,
                                      'money',
                                      totalPrice,
                                    ],
                                  );
                                  engine.hetu.invoke(
                                    'collect',
                                    namespace: 'Player',
                                    positionalArgs: ['money', totalPrice],
                                  );
                                }
                              }

                              engine.play('pickup_item-64282.mp3');
                              engine.hetu.invoke(
                                'exhaust',
                                namespace: 'Player',
                                positionalArgs: [
                                  _selectedHeroMaterialId,
                                  amount,
                                ],
                              );
                              engine.hetu
                                  .invoke('entityCollect', positionalArgs: [
                                widget.merchantData,
                                _selectedHeroMaterialId,
                                amount,
                              ]);
                              if (amount == max) {
                                _selectedHeroMaterialId = null;
                              }
                            } else {
                              final items =
                                  _selectedHeroItemsData.values.toList();
                              if (items.isEmpty) return;

                              if (!isDepositBox) {
                                int totalPrice = 0;
                                for (final itemData in items) {
                                  totalPrice += GameLogic.calculateItemPrice(
                                    itemData,
                                    priceFactor: priceFactor,
                                    isSell: true,
                                  );
                                }
                                if (widget.useShard) {
                                  if (merchantShard < totalPrice) {
                                    GameDialogContent.show(
                                        context,
                                        engine.locale(
                                            'hint_merchantNotEnoughShard'));
                                    return;
                                  }
                                  engine.hetu.invoke(
                                    'collect',
                                    namespace: 'Player',
                                    positionalArgs: ['shard', totalPrice],
                                  );
                                  engine.hetu.invoke(
                                    'entityExhaust',
                                    positionalArgs: [
                                      widget.merchantData,
                                      'shard',
                                      totalPrice,
                                    ],
                                  );
                                } else {
                                  if (merchantMoney < totalPrice) {
                                    GameDialogContent.show(
                                        context,
                                        engine.locale(
                                            'hint_merchantNotEnoughMoney'));
                                    return;
                                  }
                                  engine.hetu.invoke(
                                    'collect',
                                    namespace: 'Player',
                                    positionalArgs: ['money', totalPrice],
                                  );
                                  engine.hetu.invoke(
                                    'entityExhaust',
                                    positionalArgs: [
                                      widget.merchantData,
                                      'money',
                                      totalPrice,
                                    ],
                                  );
                                }
                              }

                              engine.play('coins-31879.mp3');
                              for (final itemData in items) {
                                engine.hetu.invoke(
                                  'lose',
                                  namespace: 'Player',
                                  positionalArgs: [itemData],
                                );
                                engine.hetu.invoke(
                                  'entityAcquire',
                                  positionalArgs: [
                                    widget.merchantData,
                                    itemData,
                                  ],
                                );
                                _selectedHeroItemsData.remove(itemData['id']);
                              }
                            }
                            context.read<HeroState>().update();
                          },
                          child: Text(
                            engine.locale(isDepositBox ? 'deposit' : 'sell'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(widget.merchantData['name']),
                      if (!isDepositBox)
                        CurrencyBar(
                          entity: widget.merchantData,
                          priceFactor: priceFactor,
                          merchantType: widget.merchantType,
                        ),
                      if (widget.materialMode)
                        MaterialList(
                          entity: widget.merchantData,
                          height: 312.0,
                          priceFactor: priceFactor,
                          selectedItem: _selectedMerchantMaterialId,
                          onSelectedItem: (item) {
                            setState(() {
                              _selectedMerchantMaterialId = item;
                            });
                          },
                        )
                      else
                        Container(
                          width: 300.0,
                          height: 312.0,
                          margin: const EdgeInsets.only(top: 10.0),
                          child: Inventory(
                            height: 350,
                            character: widget.merchantData,
                            itemType: isDepositBox
                                ? ItemType.none
                                : ItemType.merchant,
                            priceFactor: priceFactor,
                            selectedItemId: _selectedMerchantItemsData.keys,
                            onItemTapped: (itemData, screenPosition) {
                              if (_selectedMerchantItemsData
                                  .containsKey(itemData['id'])) {
                                _selectedMerchantItemsData
                                    .remove(itemData['id']);
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
                        child: fluent.FilledButton(
                          onPressed: () async {
                            int heroShard =
                                GameData.hero['materials']['shard'] ?? 0;
                            int heroMoney =
                                GameData.hero['materials']['money'] ?? 0;
                            if (widget.materialMode) {
                              if (_selectedMerchantMaterialId == null) return;
                              final int merchantHave =
                                  widget.merchantData['materials']
                                      [_selectedMerchantMaterialId];

                              final int unitPrice =
                                  GameLogic.calculateMaterialPrice(
                                _selectedMerchantMaterialId!,
                                priceFactor: priceFactor,
                                isSell: false,
                              );
                              int maxCanBuy = 0;
                              if (widget.useShard) {
                                maxCanBuy = (heroShard / unitPrice).floor();
                                if (maxCanBuy < 1) {
                                  GameDialogContent.show(context,
                                      engine.locale('hint_notEnoughShard'));
                                  return;
                                }
                              } else {
                                maxCanBuy = (heroMoney / unitPrice).floor();
                                if (maxCanBuy < 1) {
                                  GameDialogContent.show(context,
                                      engine.locale('hint_notEnoughMoney'));
                                  return;
                                }
                              }

                              final amount = await InputSliderDialog.show(
                                context: context,
                                min: 1,
                                max: math.min(merchantHave, maxCanBuy),
                                value: maxCanBuy,
                                labelBuilder: (value) {
                                  String label =
                                      '${engine.locale('amount')}: $value';
                                  if (!isDepositBox) {
                                    label +=
                                        '\n${engine.locale('totalPrice')}: ${unitPrice * value}';
                                  }
                                  return label;
                                },
                              );

                              if (amount == null) return;

                              if (!isDepositBox) {
                                final totalPrice = unitPrice * amount;

                                if (widget.useShard) {
                                  if (heroShard < totalPrice) {
                                    GameDialogContent.show(context,
                                        engine.locale('hint_notEnoughShard'));
                                    return;
                                  }
                                  engine.hetu.invoke(
                                    'exhaust',
                                    namespace: 'Player',
                                    positionalArgs: ['shard', totalPrice],
                                  );
                                  engine.hetu.invoke(
                                    'entityCollect',
                                    positionalArgs: [
                                      widget.merchantData,
                                      'shard',
                                      totalPrice,
                                    ],
                                  );
                                } else {
                                  if (heroMoney < totalPrice) {
                                    GameDialogContent.show(context,
                                        engine.locale('hint_notEnoughMoney'));
                                    return;
                                  }
                                  engine.hetu.invoke(
                                    'exhaust',
                                    namespace: 'Player',
                                    positionalArgs: ['money', totalPrice],
                                  );
                                  engine.hetu.invoke(
                                    'entityCollect',
                                    positionalArgs: [
                                      widget.merchantData,
                                      'money',
                                      totalPrice,
                                    ],
                                  );
                                }
                              }

                              engine.play('pickup_item-64282.mp3');
                              engine.hetu.invoke(
                                'collect',
                                namespace: 'Player',
                                positionalArgs: [
                                  _selectedMerchantMaterialId,
                                  amount
                                ],
                              );
                              engine.hetu.invoke(
                                'entityExhaust',
                                positionalArgs: [
                                  widget.merchantData,
                                  _selectedMerchantMaterialId,
                                  amount,
                                ],
                              );
                              if (amount == merchantHave) {
                                _selectedMerchantMaterialId = null;
                              }
                            } else {
                              final items =
                                  _selectedMerchantItemsData.values.toList();
                              if (items.isEmpty) return;

                              if (!isDepositBox) {
                                int totalPrice = 0;
                                for (final itemData in items) {
                                  if (itemData['price'] == null) {
                                    continue;
                                  }
                                  totalPrice += GameLogic.calculateItemPrice(
                                    itemData,
                                    priceFactor: priceFactor,
                                    isSell: false,
                                  );
                                }
                                if (widget.useShard) {
                                  if (heroShard < totalPrice) {
                                    GameDialogContent.show(context,
                                        engine.locale('hint_notEnoughShard'));
                                    return;
                                  }
                                  engine.hetu.invoke(
                                    'exhaust',
                                    namespace: 'Player',
                                    positionalArgs: ['shard', totalPrice],
                                  );
                                  engine.hetu.invoke(
                                    'entityCollect',
                                    positionalArgs: [
                                      widget.merchantData,
                                      'shard',
                                      totalPrice,
                                    ],
                                  );
                                } else {
                                  if (heroMoney < totalPrice) {
                                    GameDialogContent.show(context,
                                        engine.locale('hint_notEnoughMoney'));
                                    return;
                                  }
                                  engine.hetu.invoke(
                                    'exhaust',
                                    namespace: 'Player',
                                    positionalArgs: ['money', totalPrice],
                                  );
                                  engine.hetu.invoke(
                                    'entityCollect',
                                    positionalArgs: [
                                      widget.merchantData,
                                      'money',
                                      totalPrice,
                                    ],
                                  );
                                }
                              }

                              engine.play('pickup_item-64282.mp3');
                              for (final itemData in items) {
                                engine.hetu
                                    .invoke('entityLose', positionalArgs: [
                                  widget.merchantData,
                                  itemData,
                                ]);
                                await engine.hetu.invoke(
                                  'acquire',
                                  namespace: 'Player',
                                  positionalArgs: [
                                    itemData,
                                  ],
                                );
                                _selectedMerchantItemsData
                                    .remove(itemData['id']);
                              }
                            }
                            context.read<HeroState>().update();
                          },
                          child: Text(
                            engine.locale(isDepositBox ? 'take' : 'buy'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

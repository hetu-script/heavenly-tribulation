import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:samsara/widgets/ui/label.dart';

import '../../../logic/logic.dart';
import '../../../engine.dart';
import '../inventory/inventory.dart';
import '../../../data/game.dart';
import '../../../state/character.dart';
import '../../../scene/game_dialog/game_dialog_content.dart';
import 'material_bar.dart';
import '../inventory/material.dart';
import '../../dialog/input_slider.dart';
import '../../ui/close_button2.dart';
import '../../ui/responsive_view.dart';
import '../../../data/common.dart';
import '../../../state/hover_content.dart';
import '../../../ui.dart';

class MerchantDialog extends StatefulWidget {
  const MerchantDialog({
    super.key,
    required this.merchantData,
    this.useShard = false,
    this.materialMode = false,
    required this.priceFactor,
    this.filter,
    this.merchantType = MerchantType.none,
    this.allowManualReplenish = false,
  });

  final dynamic merchantData;
  final bool useShard;
  final bool materialMode;
  final bool allowManualReplenish;

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

  String? priceFactorDescription;

  bool enableReplenish = false;

  int updateDay = 0;
  int replenishCost = 0;

  @override
  void initState() {
    super.initState();

    priceFactor = widget.priceFactor ?? {};
    priceFactor['useShard'] = widget.useShard;

    enableReplenish = widget.allowManualReplenish;
    if (widget.merchantData?['entityType'] != 'location') {
      engine.warn('replenishItem 只能对 location 对象使用');
      enableReplenish = false;
    }
    if (!kSiteKindsTradable.contains(widget.merchantData?['kind'])) {
      engine.warn('场所 ${widget.merchantData['id']} 不支持物品交易刷新');
      enableReplenish = false;
    }
    if (enableReplenish) {
      updateDay = widget.merchantData?['updateDay'] ?? engine.locale('unkown');
      replenishCost = kLocationManualReplenishCostBase *
          (((widget.merchantData?['development'] as int?) ?? 0) + 1);
    }

    buildPriceFactor();
  }

  void buildPriceFactor() {
    if (priceFactor == null) return;

    final desc = StringBuffer();
    void printPriceFactor(String key, double value) {
      if (value > 1.0) {
        if (value < 1.3) {
          desc.writeln(
              '${engine.locale(key)}: <color=#FE9696>${engine.locale('expensiveSmall')} ${engine.config.debugMode ? '×$value' : ''}</>');
        } else if (value < 1.6) {
          desc.writeln(
              '${engine.locale(key)}: <color=#FF6161>${engine.locale('expensiveMedium')} ${engine.config.debugMode ? '×$value' : ''}</>');
        } else {
          desc.writeln(
              '${engine.locale(key)}: <color=#FF2222>${engine.locale('expensiveLarge')} ${engine.config.debugMode ? '×$value' : ''}</>');
        }
      } else if (value < 1.0) {
        if (value > 0.7) {
          desc.writeln(
              '${engine.locale(key)}: <color=#96FF96>${engine.locale('cheapSmall')} ${engine.config.debugMode ? '×$value' : ''}</>');
        } else if (value > 0.4) {
          desc.writeln(
              '${engine.locale(key)}: <color=#61FF61>${engine.locale('cheapMedium')} ${engine.config.debugMode ? '×$value' : ''}</>');
        } else {
          desc.writeln(
              '${engine.locale(key)}: <color=#22FF22>${engine.locale('cheapLarge')} ${engine.config.debugMode ? '×$value' : ''}</>');
        }
      } else {
        desc.writeln(
            '${engine.locale(key)}: ${engine.locale('normal')} ${engine.config.debugMode ? '×$value' : ''}');
      }
    }

    final double value = priceFactor['sell'] ?? kBaseSellRate;
    printPriceFactor('sellPriceFactor', value);

    if (priceFactor['base'] != null) {
      final double value = priceFactor['base'];
      printPriceFactor('basePriceFactor', value);
    }
    if (priceFactor['category'] != null) {
      for (final key in priceFactor['category'].keys) {
        final double value = priceFactor['category'][key];
        printPriceFactor(key, value);
      }
    }
    if (priceFactor['kind'] != null) {
      for (final key in priceFactor['kind'].keys) {
        final double value = priceFactor['kind'][key];
        printPriceFactor(key, value);
      }
    }

    priceFactorDescription = desc.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      barrierColor: null,
      width: 800.0,
      height: 600.0,
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
          padding: const EdgeInsets.only(left: 10.0, right: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 360.0,
                child: Column(
                  children: [
                    Text(GameData.hero['name']),
                    SizedBox(
                      height: 30.0,
                    ),
                    if (widget.materialMode)
                      MaterialList(
                        entity: GameData.hero,
                        height: 395.0,
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
                      Inventory(
                        height: 364.0,
                        character: GameData.hero,
                        itemType:
                            isDepositBox ? ItemType.none : ItemType.customer,
                        priceFactor: priceFactor,
                        selectedItemId: _selectedHeroItemsData.keys,
                        onItemTapped: (itemData, screenPosition) {
                          if (isDepositBox) {
                            if (_selectedHeroItemsData
                                .containsKey(itemData['id'])) {
                              _selectedHeroItemsData.remove(itemData['id']);
                            } else {
                              _selectedHeroItemsData[itemData['id']] = itemData;
                            }
                          } else {
                            if (_selectedHeroItemsData
                                .containsKey(itemData['id'])) {
                              _selectedHeroItemsData.remove(itemData['id']);
                            } else {
                              _selectedHeroItemsData.clear();
                              _selectedHeroItemsData[itemData['id']] = itemData;
                            }
                          }
                          setState(() {});
                        },
                      ),
                    if (!isDepositBox) CurrencyBar(entity: GameData.hero),
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 50.0, top: 10.0),
                          child: fluent.Button(
                            onPressed: () async {
                              int merchantMoney =
                                  widget.merchantData['materials']['money'] ??
                                      0;
                              int merchantShard =
                                  widget.merchantData['materials']['shard'] ??
                                      0;
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

                                  String currency =
                                      widget.useShard ? 'shard' : 'money';
                                  int merchantHave = widget.useShard
                                      ? merchantShard
                                      : merchantMoney;
                                  if (merchantHave < totalPrice) {
                                    GameDialogContent.show(
                                        context,
                                        engine.locale(
                                            'hint_merchantNotEnough_$currency'));
                                    return;
                                  }
                                  engine.hetu.invoke(
                                    'entityExhaust',
                                    positionalArgs: [
                                      widget.merchantData,
                                      currency,
                                      totalPrice,
                                    ],
                                  );
                                  engine.hetu.invoke(
                                    'collect',
                                    namespace: 'Player',
                                    positionalArgs: [currency, totalPrice],
                                  );
                                }

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
                                engine.play('pickup_item-64282.mp3');
                              } else {
                                if (_selectedHeroItemsData.isEmpty) return;
                                final itemsData = _selectedHeroItemsData.values;
                                if (isDepositBox) {
                                  if (itemsData.length > 1) {
                                    for (final itemData in itemsData) {
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
                                    }
                                    _selectedHeroItemsData.clear();
                                  } else {
                                    final itemData = itemsData.first;
                                    int amount = itemData['stackSize'] ?? 1;
                                    if (amount > 1) {
                                      final choosedAmount =
                                          await InputSliderDialog.show(
                                        context: context,
                                        min: 1,
                                        max: amount,
                                        value: amount,
                                        labelBuilder: (value) {
                                          String label =
                                              '${engine.locale('amount')}: $value';
                                          return label;
                                        },
                                      );
                                      if (choosedAmount == null) return;
                                      amount = choosedAmount;
                                    }
                                    engine.hetu.invoke(
                                      'lose',
                                      namespace: 'Player',
                                      positionalArgs: [itemData],
                                      namedArgs: {
                                        'amount': amount,
                                      },
                                    );
                                    engine.hetu.invoke(
                                      'entityAcquire',
                                      positionalArgs: [
                                        widget.merchantData,
                                        itemData,
                                      ],
                                      namedArgs: {
                                        'amount': amount,
                                      },
                                    );
                                    _selectedHeroItemsData
                                        .remove(itemData['id']);
                                  }
                                  engine.play('pickup_item-64282.mp3');
                                } else {
                                  assert(_selectedHeroItemsData.length <= 1);
                                  final itemData =
                                      _selectedHeroItemsData.values.first;
                                  int amount = itemData['stackSize'] ?? 1;
                                  int unitPrice = GameLogic.calculateItemPrice(
                                    itemData,
                                    priceFactor: priceFactor,
                                    useShard: widget.useShard,
                                    isSell: true,
                                  );
                                  if (amount > 1) {
                                    final choosedAmount =
                                        await InputSliderDialog.show(
                                      context: context,
                                      min: 1,
                                      max: amount,
                                      value: amount,
                                      labelBuilder: (value) {
                                        String label =
                                            '${engine.locale('amount')}: $value';
                                        label +=
                                            '\n${engine.locale('totalPrice')}: ${unitPrice * value}';
                                        return label;
                                      },
                                    );
                                    if (choosedAmount == null) return;
                                    amount = choosedAmount;
                                  }
                                  int totalPrice = unitPrice * amount;

                                  String currency =
                                      widget.useShard ? 'shard' : 'money';
                                  int merchantHave = widget.useShard
                                      ? merchantShard
                                      : merchantMoney;
                                  if (merchantHave < totalPrice) {
                                    GameDialogContent.show(
                                        context,
                                        engine.locale(
                                            'hint_merchantNotEnough_$currency'));
                                    return;
                                  }
                                  engine.hetu.invoke(
                                    'entityExhaust',
                                    positionalArgs: [
                                      widget.merchantData,
                                      currency,
                                      totalPrice,
                                    ],
                                  );
                                  engine.hetu.invoke(
                                    'collect',
                                    namespace: 'Player',
                                    positionalArgs: [currency, totalPrice],
                                  );
                                  engine.play('coins-31879.mp3');
                                  engine.hetu.invoke(
                                    'lose',
                                    namespace: 'Player',
                                    positionalArgs: [itemData],
                                    namedArgs: {
                                      'amount': amount,
                                    },
                                  );
                                  engine.hetu.invoke(
                                    'entityAcquire',
                                    positionalArgs: [
                                      widget.merchantData,
                                      itemData,
                                    ],
                                    namedArgs: {
                                      'amount': amount,
                                    },
                                  );
                                  _selectedHeroItemsData.remove(itemData['id']);
                                  engine.play('pickup_item-64282.mp3');
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
                  ],
                ),
              ),
              SizedBox(
                width: 300.0,
                child: Column(
                  children: [
                    Text(widget.merchantData['name']),
                    SizedBox(
                      height: 30.0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Image(
                            width: 24.0,
                            height: 24.0,
                            image: AssetImage('assets/images/icon/quest.png'),
                          ),
                          Label(
                            engine.locale('priceFactor'),
                            onMouseEnter: (rect) {
                              final StringBuffer content = StringBuffer();
                              if (priceFactorDescription != null) {
                                if (widget.merchantType ==
                                    MerchantType.location) {
                                  content.writeln(
                                      '${engine.locale('priceFactor')}\n${engine.locale('priceFactor_description_location')}\n \n${priceFactorDescription.toString()}');
                                } else if (widget.merchantType ==
                                    MerchantType.character) {
                                  content.writeln(
                                      '${engine.locale('priceFactor')}\n${engine.locale('priceFactor_description_character')}\n \n${priceFactorDescription.toString()}');
                                } else if (widget.merchantType ==
                                    MerchantType.productionSite) {
                                  content.writeln(
                                      '${engine.locale('priceFactor')}\n${engine.locale('priceFactor_description_productionSite')}\n \n${priceFactorDescription.toString()}');
                                } else {
                                  content.writeln(
                                      '${engine.locale('priceFactor')}\n \n${priceFactorDescription.toString()}');
                                }
                              } else {
                                content.writeln(
                                    '${engine.locale('priceFactor')}\n \n${engine.locale('none')}');
                              }
                              context.read<HoverContentState>().show(
                                    content.toString(),
                                    rect,
                                  );
                            },
                            onMouseExit: () {
                              context.read<HoverContentState>().hide();
                            },
                          ),
                        ],
                      ),
                    ),
                    if (widget.materialMode)
                      MaterialList(
                        entity: widget.merchantData,
                        height: 395.0,
                        priceFactor: priceFactor,
                        selectedItem: _selectedMerchantMaterialId,
                        onSelectedItem: (item) {
                          setState(() {
                            _selectedMerchantMaterialId = item;
                          });
                        },
                      )
                    else
                      Inventory(
                        height: 364.0,
                        character: widget.merchantData,
                        itemType:
                            isDepositBox ? ItemType.none : ItemType.merchant,
                        priceFactor: priceFactor,
                        selectedItemId: _selectedMerchantItemsData.keys,
                        onItemTapped: (itemData, screenPosition) {
                          if (isDepositBox) {
                            if (_selectedMerchantItemsData
                                .containsKey(itemData['id'])) {
                              _selectedMerchantItemsData.remove(itemData['id']);
                            } else {
                              _selectedMerchantItemsData[itemData['id']] =
                                  itemData;
                            }
                          } else {
                            if (_selectedMerchantItemsData
                                .containsKey(itemData['id'])) {
                              _selectedMerchantItemsData.remove(itemData['id']);
                            } else {
                              _selectedMerchantItemsData.clear();
                              _selectedMerchantItemsData[itemData['id']] =
                                  itemData;
                            }
                          }
                          setState(() {});
                        },
                      ),
                    if (!isDepositBox) CurrencyBar(entity: widget.merchantData),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (widget.allowManualReplenish)
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 20.0, top: 10.0, bottom: 10.0),
                            child: fluent.Button(
                              style: FluentButtonStyles.slim,
                              onPressed: () async {
                                if (!enableReplenish) return;

                                final hasMoney =
                                    GameData.hero['materials']['money'];
                                if (hasMoney < replenishCost) {
                                  dialog.pushDialog('hint_notEnough_money');
                                  await dialog.execute();
                                  return;
                                }
                                engine.hetu.invoke('exhaust',
                                    namespace: 'Player',
                                    positionalArgs: [
                                      'money',
                                      replenishCost,
                                    ]);
                                engine.hetu.invoke('replenishItem',
                                    positionalArgs: [widget.merchantData]);
                                setState(() {});
                              },
                              child: Label(
                                engine.locale('refresh'),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0, vertical: 8.0),
                                onMouseEnter: (rect) {
                                  context.read<HoverContentState>().show(
                                        engine.locale('hint_replenishLocation',
                                            interpolations: [
                                              updateDay,
                                              replenishCost,
                                            ]),
                                        rect,
                                        direction:
                                            HoverContentDirection.topCenter,
                                      );
                                },
                                onMouseExit: () {
                                  context.read<HoverContentState>().hide();
                                },
                              ),
                            ),
                          ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 10.0, bottom: 10.0, right: 20.0),
                          child: fluent.Button(
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
                                final amount = await InputSliderDialog.show(
                                  context: context,
                                  min: 1,
                                  max: merchantHave,
                                  value: merchantHave,
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

                                  String currency =
                                      widget.useShard ? 'shard' : 'money';
                                  int heroHave =
                                      widget.useShard ? heroShard : heroMoney;

                                  if (heroHave < totalPrice) {
                                    GameDialogContent.show(
                                        context,
                                        engine.locale(
                                            'hint_notEnough_$currency'));
                                    return;
                                  }
                                  engine.hetu.invoke(
                                    'exhaust',
                                    namespace: 'Player',
                                    positionalArgs: [currency, totalPrice],
                                  );
                                  engine.hetu.invoke(
                                    'entityCollect',
                                    positionalArgs: [
                                      widget.merchantData,
                                      currency,
                                      totalPrice,
                                    ],
                                  );
                                }

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
                                engine.play('pickup_item-64282.mp3');
                              } else {
                                if (_selectedMerchantItemsData.isEmpty) return;
                                final itemsData =
                                    _selectedMerchantItemsData.values;
                                if (isDepositBox) {
                                  if (itemsData.length > 1) {
                                    for (final itemData in itemsData) {
                                      engine.hetu.invoke(
                                        'entityLose',
                                        positionalArgs: [
                                          widget.merchantData,
                                          itemData,
                                        ],
                                      );
                                      await engine.hetu.invoke(
                                        'acquire',
                                        namespace: 'Player',
                                        positionalArgs: [
                                          itemData,
                                        ],
                                      );
                                    }
                                    _selectedMerchantItemsData.clear();
                                  } else {
                                    final itemData = itemsData.first;
                                    int amount = itemData['stackSize'] ?? 1;
                                    if (amount > 1) {
                                      final choosedAmount =
                                          await InputSliderDialog.show(
                                        context: context,
                                        min: 1,
                                        max: amount,
                                        value: amount,
                                        labelBuilder: (value) {
                                          String label =
                                              '${engine.locale('amount')}: $value';
                                          return label;
                                        },
                                      );
                                      if (choosedAmount == null) return;
                                      amount = choosedAmount;
                                    }
                                    engine.hetu.invoke(
                                      'entityLose',
                                      positionalArgs: [
                                        widget.merchantData,
                                        itemData,
                                      ],
                                    );
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
                                  engine.play('pickup_item-64282.mp3');
                                } else {
                                  assert(
                                      _selectedMerchantItemsData.length <= 1);
                                  final itemData =
                                      _selectedMerchantItemsData.values.first;
                                  int amount = itemData['stackSize'] ?? 1;
                                  int unitPrice = GameLogic.calculateItemPrice(
                                    itemData,
                                    priceFactor: priceFactor,
                                    useShard: widget.useShard,
                                    isSell: false,
                                  );
                                  if (amount > 1) {
                                    final choosedAmount =
                                        await InputSliderDialog.show(
                                      context: context,
                                      min: 1,
                                      max: amount,
                                      value: amount,
                                      labelBuilder: (value) {
                                        String label =
                                            '${engine.locale('amount')}: $value';
                                        label +=
                                            '\n${engine.locale('totalPrice')}: ${unitPrice * value}';
                                        return label;
                                      },
                                    );
                                    if (choosedAmount == null) return;
                                    amount = choosedAmount;
                                  }
                                  int totalPrice = unitPrice * amount;

                                  String currency =
                                      widget.useShard ? 'shard' : 'money';
                                  int heroHave =
                                      widget.useShard ? heroShard : heroMoney;

                                  if (heroHave < totalPrice) {
                                    GameDialogContent.show(
                                        context,
                                        engine.locale(
                                            'hint_notEnough_$currency'));
                                    return;
                                  }
                                  engine.hetu.invoke(
                                    'exhaust',
                                    namespace: 'Player',
                                    positionalArgs: [currency, totalPrice],
                                  );
                                  engine.hetu.invoke(
                                    'entityCollect',
                                    positionalArgs: [
                                      widget.merchantData,
                                      currency,
                                      totalPrice,
                                    ],
                                  );

                                  engine.hetu.invoke(
                                    'entityLose',
                                    positionalArgs: [
                                      widget.merchantData,
                                      itemData,
                                    ],
                                    namedArgs: {
                                      'amount': amount,
                                    },
                                  );
                                  await engine.hetu.invoke(
                                    'acquire',
                                    namespace: 'Player',
                                    positionalArgs: [
                                      itemData,
                                    ],
                                    namedArgs: {
                                      'amount': amount,
                                    },
                                  );
                                  _selectedMerchantItemsData
                                      .remove(itemData['id']);
                                  engine.play('pickup_item-64282.mp3');
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

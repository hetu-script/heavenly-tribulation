import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:samsara/widgets/ui/label.dart';
import 'package:samsara/hover_info.dart';

import '../../../extensions.dart';
import '../../../logic/logic.dart';
import '../../../global.dart';
import '../inventory/inventory.dart';
import '../inventory/item_grid.dart';
import '../../../data/game.dart';
import '../../../state/character.dart';
import 'currency_bar.dart';
import '../inventory/material.dart';
import '../../dialog/input_slider.dart';
import '../../ui/close_button2.dart';
import '../../ui/responsive_view.dart';
import '../../../data/common.dart';
import '../../../ui.dart';
import '../../common.dart';

const _tempTradeGridCount = 15;

int _getShardPrice(int price) {
  final shardToMoneyRate = kMaterialPrice['shard'] as int;
  final finalPrice = (price / shardToMoneyRate).ceil();
  return finalPrice;
}

class _ItemEntry {
  final dynamic itemData;
  final int amount;
  final bool isPlayerItem; // true = sell (hero), false = buy (merchant)
  final int unitPrice;
  final String currency; // 'money' or 'shard'

  const _ItemEntry({
    required this.itemData,
    required this.amount,
    this.isPlayerItem = false,
    this.unitPrice = 0,
    this.currency = 'money',
  });

  int get totalPrice => unitPrice * amount;
  String get itemId => itemData['id'];
  int get stackSize => itemData['stackSize'] ?? 1;
}

class MerchantDialog extends StatefulWidget {
  const MerchantDialog({
    super.key,
    required this.merchantData,
    this.useShard = false,
    this.materialMode = false,
    required this.priceFactor,
    this.filter,
    this.merchantType = MerchantType.none,
    this.enalbeReplenish = false,
    this.enalbeSteal = false,
  });

  final dynamic merchantData;
  final bool useShard;
  final bool materialMode;
  final bool enalbeReplenish;
  final bool enalbeSteal;

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

  final List<_ItemEntry> _tradeEntries = [];

  bool get isDepositBox => widget.merchantType == MerchantType.depositBox;

  Iterable<String> get _selectedHeroIds =>
      _tradeEntries.where((e) => e.isPlayerItem).map((e) => e.itemId);

  Iterable<String> get _selectedMerchantIds =>
      _tradeEntries.where((e) => !e.isPlayerItem).map((e) => e.itemId);

  int get _netMoney {
    int money = 0;
    for (final e in _tradeEntries) {
      if (e.currency == 'money') {
        money += e.isPlayerItem ? e.totalPrice : -e.totalPrice;
      }
    }
    return money;
  }

  int get _netShard {
    int shard = 0;
    for (final e in _tradeEntries) {
      if (e.currency == 'shard') {
        shard += e.isPlayerItem ? e.totalPrice : -e.totalPrice;
      }
    }
    return shard;
  }

  String? _selectedHeroMaterialId, _selectedMerchantMaterialId;

  dynamic priceFactor;
  String? priceFactorDescription;

  int development = 0;
  bool enableReplenish = false;
  int replenishCount = 0;
  int updateDay = 0;
  int replenishCostBase = 0;
  int replenishCost = 0;

  @override
  void initState() {
    super.initState();

    priceFactor = widget.priceFactor ?? {};
    priceFactor['useShard'] = widget.useShard;

    development = widget.merchantData?['development'] as int? ?? 0;

    enableReplenish = widget.enalbeReplenish;
    if (widget.merchantData?['entityType'] != 'location') {
      enableReplenish = false;
    }
    if (!kSiteKindsTradable.contains(widget.merchantData?['kind'])) {
      enableReplenish = false;
    }
    if (enableReplenish) {
      updateDay = widget.merchantData?['updateDay'] ?? engine.locale('unkown');
      int? c = widget.merchantData['flags']['monthly']['replenishCount'];
      c ??= widget.merchantData['flags']['monthly']['replenishCount'] = 0;
      replenishCount = c;
      replenishCostBase =
          kLocationManualReplenishCostBase * (development * development + 1);
      replenishCost =
          (replenishCostBase * (1.5 * (replenishCount + 1))).round();
    }

    buildPriceFactor();
  }

  void updateReplenishCount() {
    replenishCount = widget.merchantData['flags']['monthly']['replenishCount'] =
        replenishCount + 1;
    replenishCost = (replenishCostBase * (1.5 * replenishCount)).round();
  }

  void buildPriceFactor() {
    if (priceFactor == null) return;

    final desc = StringBuffer();
    void printPriceFactor(String key, double value) {
      if (value > 1.0) {
        if (value < 1.3) {
          desc.writeln(
              '${engine.locale(key)}: <color=#FE9696>${engine.locale('expensiveSmall')} ${engine.config.developMode ? '×$value' : ''}</>');
        } else if (value < 1.6) {
          desc.writeln(
              '${engine.locale(key)}: <color=#FF6161>${engine.locale('expensiveMedium')} ${engine.config.developMode ? '×$value' : ''}</>');
        } else {
          desc.writeln(
              '${engine.locale(key)}: <color=#FF2222>${engine.locale('expensiveLarge')} ${engine.config.developMode ? '×$value' : ''}</>');
        }
      } else if (value < 1.0) {
        if (value > 0.7) {
          desc.writeln(
              '${engine.locale(key)}: <color=#96FF96>${engine.locale('cheapSmall')} ${engine.config.developMode ? '×$value' : ''}</>');
        } else if (value > 0.4) {
          desc.writeln(
              '${engine.locale(key)}: <color=#61FF61>${engine.locale('cheapMedium')} ${engine.config.developMode ? '×$value' : ''}</>');
        } else {
          desc.writeln(
              '${engine.locale(key)}: <color=#22FF22>${engine.locale('cheapLarge')} ${engine.config.developMode ? '×$value' : ''}</>');
        }
      } else {
        desc.writeln(
            '${engine.locale(key)}: ${engine.locale('normal')} ${engine.config.developMode ? '×$value' : ''}');
      }
    }

    final double value = priceFactor['sell'] ?? kSellRateBase;
    printPriceFactor('sellPriceFactor', value);

    if (priceFactor['base'] != null) {
      final double value = priceFactor['base'];
      printPriceFactor('basePriceFactor', value);
    }

    if (widget.materialMode) {
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
    }

    priceFactorDescription = desc.toString().trim();
  }

  void _onSell() async {
    int merchantMoney = widget.merchantData['materials']['money'] ?? 0;
    int merchantShard = widget.merchantData['materials']['shard'] ?? 0;
    if (widget.materialMode) {
      if (_selectedHeroMaterialId == null) return;
      final int max = GameData.hero['materials'][_selectedHeroMaterialId];
      final int unitPrice = GameLogic.calculateMaterialPrice(
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
          String label = '${engine.locale('amount')}: $value';
          if (!isDepositBox) {
            label += '\n${engine.locale('totalPrice')}: ${unitPrice * value}';
          }
          return label;
        },
      );
      if (amount == null) return;

      if (!isDepositBox) {
        final totalPrice = unitPrice * amount;

        String currency = widget.useShard ? 'shard' : 'money';
        int merchantHave = widget.useShard ? merchantShard : merchantMoney;
        if (merchantHave < totalPrice) {
          dialog.pushDialog('hint_merchantNotEnough_$currency');
          dialog.execute();
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
      engine.hetu.invoke('entityCollect', positionalArgs: [
        widget.merchantData,
        _selectedHeroMaterialId,
        amount,
      ]);
      if (amount == max) {
        _selectedHeroMaterialId = null;
      }
      engine.play(GameSound.pickup);
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
            final choosedAmount = await InputSliderDialog.show(
              context: context,
              min: 1,
              max: amount,
              value: amount,
              labelBuilder: (value) {
                String label = '${engine.locale('amount')}: $value';
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
          _selectedHeroItemsData.remove(itemData['id']);
        }
        engine.play(GameSound.pickup);
      } else {
        if (itemsData.length > 1) {
          int totalPrice = 0;
          for (final itemData in itemsData) {
            totalPrice += GameLogic.calculateItemPrice(
              itemData,
              priceFactor: priceFactor,
              isSell: true,
            );
          }

          String currency =
              (widget.useShard && totalPrice >= 1000) ? 'shard' : 'money';
          int merchantHave = widget.useShard ? merchantShard : merchantMoney;
          if (merchantHave < totalPrice) {
            dialog.pushDialog('hint_merchantNotEnough_$currency');
            dialog.execute();
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
          engine.play(GameSound.coins);
          for (final itemData in itemsData) {
            engine.hetu.invoke(
              'lose',
              namespace: 'Player',
              positionalArgs: [itemData],
              namedArgs: {'amount': 1},
            );
            engine.hetu.invoke(
              'entityAcquire',
              positionalArgs: [
                widget.merchantData,
                itemData,
              ],
              namedArgs: {'amount': 1},
            );
          }
          _selectedHeroItemsData.clear();
          engine.play(GameSound.pickup);
        } else {
          final itemData = _selectedHeroItemsData.values.first;
          int amount = itemData['stackSize'] ?? 1;
          int unitPrice = GameLogic.calculateItemPrice(
            itemData,
            priceFactor: priceFactor,
            isSell: true,
          );
          if (amount > 1) {
            final choosedAmount = await InputSliderDialog.show(
              context: context,
              min: 1,
              max: amount,
              value: amount,
              labelBuilder: (value) {
                String label = '${engine.locale('amount')}: $value';
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
              (widget.useShard && totalPrice >= 1000) ? 'shard' : 'money';
          int merchantHave = widget.useShard ? merchantShard : merchantMoney;
          if (merchantHave < totalPrice) {
            dialog.pushDialog('hint_merchantNotEnough_$currency');
            dialog.execute();
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
          engine.play(GameSound.coins);
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
          engine.play(GameSound.pickup);
        }
      }
    }
    gameState.updateUI();
  }

  void _onBuy() async {
    int heroShard = GameData.hero['materials']['shard'] ?? 0;
    int heroMoney = GameData.hero['materials']['money'] ?? 0;
    if (widget.materialMode) {
      if (_selectedMerchantMaterialId == null) return;
      final int merchantHave =
          widget.merchantData['materials'][_selectedMerchantMaterialId];
      final int unitPrice = GameLogic.calculateMaterialPrice(
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
          String label = '${engine.locale('amount')}: $value';
          if (!isDepositBox) {
            label += '\n${engine.locale('totalPrice')}: ${unitPrice * value}';
          }
          return label;
        },
      );
      if (amount == null) return;

      if (!isDepositBox) {
        final totalPrice = unitPrice * amount;
        String currency = 'money';
        if (heroMoney < totalPrice) {
          dialog.pushDialog('hint_notEnough_$currency');
          dialog.execute();
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
        positionalArgs: [_selectedMerchantMaterialId, amount],
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
      engine.play(GameSound.pickup);
    } else {
      if (_selectedMerchantItemsData.isEmpty) return;
      final itemsData = _selectedMerchantItemsData.values;
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
            final choosedAmount = await InputSliderDialog.show(
              context: context,
              min: 1,
              max: amount,
              value: amount,
              labelBuilder: (value) {
                String label = '${engine.locale('amount')}: $value';
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
          _selectedMerchantItemsData.remove(itemData['id']);
        }
        engine.play(GameSound.pickup);
      } else {
        if (itemsData.length > 1) {
          int totalPrice = 0;
          for (final itemData in itemsData) {
            totalPrice += GameLogic.calculateItemPrice(
              itemData,
              priceFactor: priceFactor,
              isSell: false,
            );
          }

          String currency =
              (widget.useShard && totalPrice >= 1000) ? 'shard' : 'money';

          int heroHave = widget.useShard ? heroShard : heroMoney;

          if (heroHave < totalPrice) {
            dialog.pushDialog('hint_notEnough_$currency');
            dialog.execute();
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

          for (final itemData in itemsData) {
            engine.hetu.invoke(
              'entityLose',
              positionalArgs: [
                widget.merchantData,
                itemData,
              ],
              namedArgs: {'amount': 1},
            );
            await engine.hetu.invoke(
              'acquire',
              namespace: 'Player',
              positionalArgs: [
                itemData,
              ],
              namedArgs: {'amount': 1},
            );
          }
          _selectedMerchantItemsData.clear();
          engine.play(GameSound.pickup);
        } else {
          final itemData = _selectedMerchantItemsData.values.first;
          int amount = itemData['stackSize'] ?? 1;
          int unitPrice = GameLogic.calculateItemPrice(
            itemData,
            priceFactor: priceFactor,
            isSell: false,
          );
          if (amount > 1) {
            final choosedAmount = await InputSliderDialog.show(
              context: context,
              min: 1,
              max: amount,
              value: amount,
              labelBuilder: (value) {
                String label = '${engine.locale('amount')}: $value';
                label +=
                    '\n${engine.locale('totalPrice')}: ${unitPrice * value}';
                return label;
              },
            );
            if (choosedAmount == null) return;
            amount = choosedAmount;
          }
          int totalPrice = unitPrice * amount;

          bool useShard = widget.useShard && totalPrice >= 1000;
          String currency = useShard ? 'shard' : 'money';
          if (useShard) {
            totalPrice = _getShardPrice(totalPrice);
          }

          int heroHave = widget.useShard ? heroShard : heroMoney;

          if (heroHave < totalPrice) {
            dialog.pushDialog('hint_notEnough_$currency');
            dialog.execute();
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
          _selectedMerchantItemsData.remove(itemData['id']);
          engine.play(GameSound.pickup);
        }
      }
    }
    gameState.updateUI();
  }

  void _onReplenish() async {
    if (!enableReplenish) return;
    await GameLogic.updateGame();
    final hasMoney = GameData.hero['materials']['money'] ?? 0;
    if (hasMoney < replenishCost) {
      dialog.pushDialog('hint_notEnough_money');
      await dialog.execute();
      return;
    }
    context.read<HoverContentState>().hide();
    engine.hetu.invoke('exhaust',
        namespace: 'Player', positionalArgs: ['money', replenishCost]);
    engine.hetu
        .invoke('replenishTradingItem', positionalArgs: [widget.merchantData]);
    updateReplenishCount();
    engine.play(GameSound.pickup);
    setState(() {});
  }

  void _onHeroItemTapped(dynamic itemData, Offset screenPosition) async {
    final id = itemData['id'] as String;

    final existingIndex =
        _tradeEntries.indexWhere((e) => e.isPlayerItem && e.itemId == id);
    if (existingIndex >= 0) {
      setState(() => _tradeEntries.removeAt(existingIndex));
      return;
    }

    if (_tradeEntries.length >= 15) return;

    final int price = GameLogic.calculateItemPrice(
      itemData,
      priceFactor: priceFactor,
      isSell: true,
    );
    final useShard = widget.useShard && price >= 1000;
    final String currency = useShard ? 'shard' : 'money';
    final finalPrice = useShard ? _getShardPrice(price) : price;

    int amount = 1;
    final int stackSize = itemData['stackSize'] ?? 1;
    if (stackSize > 1) {
      final chosen = await InputSliderDialog.show(
        context: context,
        min: 1,
        max: stackSize,
        value: stackSize,
        labelBuilder: (value) {
          String label = '${engine.locale('amount')}: $value';
          label += '\n${engine.locale('totalPrice')}: ${price * value}';
          return label;
        },
      );
      if (chosen == null) return;
      amount = chosen;
    }

    setState(() {
      _tradeEntries.add(_ItemEntry(
        itemData: itemData,
        amount: amount,
        isPlayerItem: true,
        unitPrice: finalPrice,
        currency: currency,
      ));
    });
  }

  void _onMerchantItemTapped(dynamic itemData, Offset screenPosition) async {
    final id = itemData['id'] as String;

    final existingIndex =
        _tradeEntries.indexWhere((e) => !e.isPlayerItem && e.itemId == id);
    if (existingIndex >= 0) {
      setState(() => _tradeEntries.removeAt(existingIndex));
      return;
    }

    if (_tradeEntries.length >= 15) return;

    final int price = GameLogic.calculateItemPrice(
      itemData,
      priceFactor: priceFactor,
      isSell: false,
    );
    final useShard = widget.useShard && price >= 1000;
    final String currency = useShard ? 'shard' : 'money';
    final finalPrice = useShard ? _getShardPrice(price) : price;

    int amount = 1;
    final int stackSize = itemData['stackSize'] ?? 1;
    if (stackSize > 1) {
      final chosen = await InputSliderDialog.show(
        context: context,
        min: 1,
        max: stackSize,
        value: stackSize,
        labelBuilder: (value) {
          String label = '${engine.locale('amount')}: $value';
          label += '\n${engine.locale('totalPrice')}: ${finalPrice * value}';
          return label;
        },
      );
      if (chosen == null) return;
      amount = chosen;
    }

    setState(() {
      _tradeEntries.add(_ItemEntry(
        itemData: itemData,
        amount: amount,
        isPlayerItem: false,
        unitPrice: finalPrice,
        currency: currency,
      ));
    });
  }

  void _onTrade() async {
    assert(_tradeEntries.isNotEmpty);

    final int heroMoney = GameData.hero['materials']['money'] ?? 0;
    final int heroShard = GameData.hero['materials']['shard'] ?? 0;
    final int merchantMoney = widget.merchantData['materials']['money'] ?? 0;
    final int merchantShard = widget.merchantData['materials']['shard'] ?? 0;

    int buyMoneyCost = 0;
    int buyShardCost = 0;
    for (final e in _tradeEntries.where((e) => !e.isPlayerItem)) {
      if (e.currency == 'money') {
        buyMoneyCost += e.totalPrice;
      } else {
        buyShardCost += e.totalPrice;
      }
    }

    int sellMoneyIncome = 0;
    int sellShardIncome = 0;
    for (final e in _tradeEntries.where((e) => e.isPlayerItem)) {
      if (e.currency == 'money') {
        sellMoneyIncome += e.totalPrice;
      } else {
        sellShardIncome += e.totalPrice;
      }
    }

    if (heroMoney < buyMoneyCost) {
      dialog.pushDialog('hint_notEnough_money');
      dialog.execute();
      return;
    }
    if (heroShard < buyShardCost) {
      dialog.pushDialog('hint_notEnough_shard');
      dialog.execute();
      return;
    }
    if (merchantMoney < sellMoneyIncome) {
      dialog.pushDialog('hint_merchantNotEnough_money');
      dialog.execute();
      return;
    }
    if (merchantShard < sellShardIncome) {
      dialog.pushDialog('hint_merchantNotEnough_shard');
      dialog.execute();
      return;
    }

    final netMoney = sellMoneyIncome - buyMoneyCost;
    if (netMoney > 0) {
      engine.hetu.invoke('collect',
          namespace: 'Player', positionalArgs: ['money', netMoney]);
      engine.hetu.invoke('entityExhaust',
          positionalArgs: [widget.merchantData, 'money', netMoney]);
      engine.play(GameSound.coins);
    } else if (netMoney < 0) {
      final toPay = -netMoney;
      engine.hetu.invoke('exhaust',
          namespace: 'Player', positionalArgs: ['money', toPay]);
      engine.hetu.invoke('entityCollect',
          positionalArgs: [widget.merchantData, 'money', toPay]);
    }

    final netShard = sellShardIncome - buyShardCost;
    if (netShard > 0) {
      engine.hetu.invoke('collect',
          namespace: 'Player', positionalArgs: ['shard', netShard]);
      engine.hetu.invoke('entityExhaust',
          positionalArgs: [widget.merchantData, 'shard', netShard]);
      if (netMoney == 0) engine.play(GameSound.coins);
    } else if (netShard < 0) {
      final toPay = -netShard;
      engine.hetu.invoke('exhaust',
          namespace: 'Player', positionalArgs: ['shard', toPay]);
      engine.hetu.invoke('entityCollect',
          positionalArgs: [widget.merchantData, 'shard', toPay]);
    }

    for (final entry in _tradeEntries) {
      if (entry.isPlayerItem) {
        if (entry.amount == entry.stackSize) {
          engine.hetu.invoke('lose',
              namespace: 'Player', positionalArgs: [entry.itemData]);
          engine.hetu.invoke('entityAcquire',
              positionalArgs: [widget.merchantData, entry.itemData]);
        } else {
          engine.hetu.invoke('lose',
              namespace: 'Player',
              positionalArgs: [entry.itemData],
              namedArgs: {'amount': entry.amount});
          engine.hetu.invoke('entityAcquire',
              positionalArgs: [widget.merchantData, entry.itemData],
              namedArgs: {'amount': entry.amount});
        }
      } else {
        if (entry.amount == entry.stackSize) {
          engine.hetu.invoke('entityLose',
              positionalArgs: [widget.merchantData, entry.itemData]);
          await engine.hetu.invoke('acquire',
              namespace: 'Player', positionalArgs: [entry.itemData]);
        } else {
          engine.hetu.invoke('entityLose',
              positionalArgs: [widget.merchantData, entry.itemData],
              namedArgs: {'amount': entry.amount});
          await engine.hetu.invoke('acquire',
              namespace: 'Player',
              positionalArgs: [entry.itemData],
              namedArgs: {'amount': entry.amount});
        }
      }
    }

    engine.play(GameSound.pickup);

    setState(() {
      _tradeEntries.clear();
    });
    gameState.updateUI();
  }

  void close() {
    context.read<MerchantState>().close();
  }

  @override
  Widget build(BuildContext context) {
    if (isDepositBox || widget.materialMode) {
      return _buildTradeLayout1();
    } else {
      return _buildTradeLayout2();
    }
  }

  Widget _buildTradeLayout1() {
    return ResponsiveView(
      width: 700.0,
      height: 590.0,
      barrierDismissible: false,
      // onBarrierDismissed: close,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale(isDepositBox ? 'exchange' : 'trade')),
          actions: [CloseButton2(onPressed: close)],
        ),
        body: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLeftPanel(),
            _buildRightPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      width: 320.0,
      padding: const EdgeInsets.only(left: 20.0, right: 20.0),
      child: Column(
        children: [
          Text(GameData.hero['name']),
          SizedBox(height: 30.0),
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
              inventoryType:
                  isDepositBox ? InventoryType.none : InventoryType.customer,
              priceFactor: priceFactor,
              selectedItemIds: _selectedHeroItemsData.keys,
              onItemTapped: (itemData, screenPosition) {
                if (isDepositBox) {
                  if (_selectedHeroItemsData.containsKey(itemData['id'])) {
                    _selectedHeroItemsData.remove(itemData['id']);
                  } else {
                    _selectedHeroItemsData[itemData['id']] = itemData;
                  }
                } else {
                  if (_selectedHeroItemsData.containsKey(itemData['id'])) {
                    _selectedHeroItemsData.remove(itemData['id']);
                  } else {
                    _selectedHeroItemsData[itemData['id']] = itemData;
                  }
                }
                setState(() {});
              },
            ),
          if (!isDepositBox)
            Padding(
              padding: const EdgeInsets.only(left: 15.0, top: 5.0),
              child: CurrencyBar(
                entity: GameData.hero,
                showMaterialName: false,
              ),
            ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 15.0, top: 10.0),
                child: fluent.Button(
                  onPressed: _onSell,
                  child: Text(
                    engine.locale(isDepositBox ? 'deposit' : 'sell'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      width: 320.0,
      padding: const EdgeInsets.only(left: 20.0, right: 20.0),
      child: Column(
        children: [
          Text(widget.merchantData['name']),
          if (!isDepositBox)
            SizedBox(
              height: 30.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                        if (widget.merchantType == MerchantType.location &&
                            widget.materialMode) {
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
                          content.write(
                              '${engine.locale('priceFactor')}\n \n${priceFactorDescription.toString()}');
                        }
                      } else {
                        content.writeln(
                            '${engine.locale('priceFactor')}\n \n${engine.locale('none')}');
                      }
                      context.read<HoverContentState>().show(
                            rect: rect,
                            data: content.toString(),
                          );
                    },
                    onMouseExit: () {
                      context.read<HoverContentState>().hide();
                    },
                  ),
                ],
              ),
            )
          else
            SizedBox(height: 30.0),
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
              inventoryType:
                  isDepositBox ? InventoryType.none : InventoryType.merchant,
              priceFactor: priceFactor,
              selectedItemIds: _selectedMerchantItemsData.keys,
              onItemTapped: (itemData, screenPosition) {
                if (isDepositBox) {
                  if (_selectedMerchantItemsData.containsKey(itemData['id'])) {
                    _selectedMerchantItemsData.remove(itemData['id']);
                  } else {
                    _selectedMerchantItemsData[itemData['id']] = itemData;
                  }
                } else {
                  if (_selectedMerchantItemsData.containsKey(itemData['id'])) {
                    _selectedMerchantItemsData.remove(itemData['id']);
                  } else {
                    _selectedMerchantItemsData[itemData['id']] = itemData;
                  }
                }
                setState(() {});
              },
            ),
          if (!isDepositBox)
            Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: CurrencyBar(
                entity: widget.merchantData,
                showMaterialName: false,
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.enalbeReplenish && replenishCount < 5)
                Padding(
                  padding: const EdgeInsets.only(left: 15.0, top: 10.0),
                  child: fluent.Button(
                    style: FluentButtonStyles.slim,
                    onPressed: () async {
                      if (!enableReplenish) return;
                      await GameLogic.updateGame();
                      final hasMoney = GameData.hero['materials']['money'] ?? 0;
                      if (hasMoney < replenishCost) {
                        dialog.pushDialog('hint_notEnough_money');
                        await dialog.execute();
                        return;
                      }
                      context.read<HoverContentState>().hide();
                      engine.hetu.invoke('exhaust',
                          namespace: 'Player',
                          positionalArgs: [
                            'money',
                            replenishCost,
                          ]);
                      engine.hetu.invoke('replenishTradingItem',
                          positionalArgs: [widget.merchantData]);
                      updateReplenishCount();
                      engine.play(GameSound.pickup);
                      setState(() {});
                    },
                    child: Label(
                      engine.locale('refresh'),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      onMouseEnter: (rect) {
                        context.read<HoverContentState>().show(
                              rect: rect,
                              data: engine.locale('hint_replenishLocation',
                                  interpolations: [
                                    updateDay,
                                    replenishCount,
                                    replenishCost,
                                  ]),
                              direction: HoverContentDirection.topCenter,
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
                padding: const EdgeInsets.only(top: 10.0, right: 15.0),
                child: fluent.Button(
                  onPressed: _onBuy,
                  child: Text(
                    engine.locale(isDepositBox ? 'take' : 'buy'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTradeLayout2() {
    return ResponsiveView(
      width: 800.0,
      height: 590.0,
      barrierDismissible: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('trade')),
          actions: [CloseButton2(onPressed: close)],
        ),
        body: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHeroPanel(),
            _buildMiddlePanel(),
            _buildMerchantPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroPanel() {
    return SizedBox(
      width: 300.0,
      child: Column(
        children: [
          Text(GameData.hero['name']),
          const SizedBox(height: 30.0),
          Inventory(
            height: 364.0,
            character: GameData.hero,
            inventoryType: InventoryType.customer,
            priceFactor: priceFactor,
            selectedItemIds: _selectedHeroIds,
            onItemTapped: _onHeroItemTapped,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0, top: 5.0),
            child: CurrencyBar(
              entity: GameData.hero,
              showMaterialName: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantPanel() {
    return SizedBox(
      width: 300.0,
      child: Column(
        children: [
          Text(widget.merchantData['name']),
          SizedBox(
            height: 30.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
                      if (widget.merchantType == MerchantType.location &&
                          widget.materialMode) {
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
                        content.write(
                            '${engine.locale('priceFactor')}\n \n${priceFactorDescription.toString()}');
                      }
                    } else {
                      content.writeln(
                          '${engine.locale('priceFactor')}\n \n${engine.locale('none')}');
                    }
                    context.read<HoverContentState>().show(
                          rect: rect,
                          data: content.toString(),
                        );
                  },
                  onMouseExit: () {
                    context.read<HoverContentState>().hide();
                  },
                ),
              ],
            ),
          ),
          Inventory(
            height: 364.0,
            character: widget.merchantData,
            inventoryType: InventoryType.merchant,
            priceFactor: priceFactor,
            selectedItemIds: _selectedMerchantIds,
            onItemTapped: _onMerchantItemTapped,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0),
            child: CurrencyBar(
              entity: widget.merchantData,
              showMaterialName: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiddlePanel() {
    return Container(
      width: 190.0,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 15.0),
          _buildTempTradeGrid(),
          const SizedBox(height: 10.0),
          _buildSettlementPreview(),
          const SizedBox(height: 10.0),
          SizedBox(
            width: 156.0,
            child: fluent.Button(
              onPressed: _tradeEntries.isNotEmpty ? _onTrade : null,
              child: Text(engine.locale('trade')),
            ),
          ),
          if (widget.enalbeReplenish && replenishCount < 5)
            Container(
              width: 156.0,
              padding: const EdgeInsets.only(bottom: 6.0),
              child: fluent.Button(
                style: FluentButtonStyles.slim,
                onPressed: _onReplenish,
                child: Label(
                  engine.locale('refresh'),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  onMouseEnter: (rect) {
                    context.read<HoverContentState>().show(
                          rect: rect,
                          data: engine.locale('hint_replenishLocation',
                              interpolations: [
                                updateDay,
                                replenishCount,
                                replenishCost,
                              ]),
                          direction: HoverContentDirection.topCenter,
                        );
                  },
                  onMouseExit: () {
                    context.read<HoverContentState>().hide();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTempTradeGrid() {
    return SizedBox(
      width: 156.0,
      height: 260.0,
      child: ListView(
        shrinkWrap: true,
        children: [
          Wrap(
            alignment: WrapAlignment.start,
            children: List.generate(_tempTradeGridCount, (index) {
              if (index < _tradeEntries.length) {
                return _buildTradeGridCell(_tradeEntries[index], index);
              }
              return const ItemGrid(
                size: kDefaultItemGridSize,
                margin: EdgeInsets.all(2.0),
              );
            }),
          )
        ],
      ),
    );
  }

  Widget _buildTradeGridCell(_ItemEntry entry, int index) {
    final inventoryType =
        entry.isPlayerItem ? InventoryType.customer : InventoryType.merchant;

    return ItemGrid(
      size: kDefaultItemGridSize,
      itemData: entry.itemData,
      margin: EdgeInsets.all(2.0),
      showStackNumber: false,
      borderColor: entry.isPlayerItem ? Colors.yellow : Colors.blue,
      onTapped: (_, __) {
        setState(() => _tradeEntries.removeAt(index));
      },
      onMouseEnter: (itemData, rect) {
        context.read<HoverContentState>().show(
              rect: rect,
              contentBuilder: (isDetailed) => buildItemHoverInfo(
                entry.itemData,
                inventoryType: inventoryType,
                isDetailed: isDetailed,
                priceFactor: priceFactor,
              ),
            );
      },
      onMouseExit: () {
        context.read<HoverContentState>().hide();
      },
      child: Stack(
        children: [
          if (entry.amount > 1)
            Positioned(
              right: 1,
              bottom: -3,
              child: Text(
                entry.amount.toString(),
                style: const TextStyle(
                  color: Colors.yellow,
                  fontSize: 11.0,
                  shadows: [
                    Shadow(
                      blurRadius: 4.0,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettlementPreview() {
    final netMoney = _netMoney;
    final netShard = _netShard;

    final moneyColor = netMoney > 0
        ? const Color(0xff66bb6a)
        : (netMoney < 0 ? const Color(0xffef5350) : Colors.grey);
    final shardColor = netShard > 0
        ? const Color(0xff66bb6a)
        : (netShard < 0 ? const Color(0xffef5350) : Colors.grey);

    final moneySign = netMoney > 0 ? '+' : '';
    final moneyString = '$moneySign$netMoney'.padLeft(12);
    final shardSign = netShard > 0 ? '+' : '';
    final shardString = '$shardSign$netShard'.padLeft(12);

    return SizedBox(
      width: 150.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Image(
                width: 16.0,
                height: 16.0,
                image: AssetImage('assets/images/item/material/money.png'),
              ),
              const SizedBox(width: 4.0),
              Text(
                '${engine.locale('money')}: $moneyString',
                style: TextStyles.bodySmall.copyWith(color: moneyColor),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Image(
                width: 16.0,
                height: 16.0,
                image: AssetImage('assets/images/item/material/shard.png'),
              ),
              const SizedBox(width: 4.0),
              Text(
                '${engine.locale('shard')}: $shardString',
                style: TextStyles.bodySmall.copyWith(color: shardColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

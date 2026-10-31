import 'dart:math' as math;

import '../../data/constants.dart';

/// 费用条目为整数，或求值后的 {base, isDynamic}（Map / HTStruct）。
int cardCostBase(dynamic entry) =>
    entry is num ? entry.toInt() : (entry?['base'] as num?)?.toInt() ?? 0;

bool isDynamicCardCost(dynamic entry) =>
    entry != null && entry is! num && entry['isDynamic'] == true;

/// 抽牌置零效果只清除普通费用，保留动态条目及门槛。
void clearReducibleCardCosts(dynamic costs) {
  if (costs == null) return;
  for (final color in costs.keys.toList()) {
    if (!isDynamicCardCost(costs[color])) costs[color] = 0;
  }
}

/// 按卡牌汇总全部命中的组牌费用规则，再统一执行下限与动态费用豁免。
void applyDeckCostReductionRules(
    Iterable<dynamic> cardDataList, dynamic rules) {
  for (final cardData in cardDataList) {
    final cost = cardData['coloredCost'];
    if (cost == null) continue;
    final costDeltas = <String, int>{};
    for (final rule in rules ?? const []) {
      final color = rule['color'];
      final amount = rule['amount'];
      if (color is! String || amount is! num || amount == 0) continue;
      final genres = rule['genres'];
      final notGenres = rule['notGenres'];
      final genre = cardData['genre'];
      if (genres is List && !genres.contains(genre)) continue;
      if (notGenres is List && notGenres.contains(genre)) continue;
      if (color == 'all') {
        if (cost.isNotEmpty) {
          final targetColor = cost.keys.first as String;
          costDeltas[targetColor] =
              (costDeltas[targetColor] ?? 0) - amount.toInt();
        } else if (amount < 0) {
          final explicit = cardData['affixes'][0]['coloredCost'];
          if (explicit != null && explicit.isNotEmpty) {
            final targetColor = explicit.keys.first as String;
            costDeltas[targetColor] =
                (costDeltas[targetColor] ?? 0) - amount.toInt();
          }
        }
      } else if (cost[color] != null) {
        costDeltas[color] = (costDeltas[color] ?? 0) - amount.toInt();
      }
    }
    for (final entry in costDeltas.entries) {
      modifyCardCost(cost, entry.key, entry.value);
    }
  }
}

/// 修改基础门槛，返回实际修正量；动态费用不参与减费。
/// 还原旧修正时关闭减费豁免，避免临时加费永久累积。
int modifyCardCost(dynamic costs, String color, int delta,
    {bool restoring = false}) {
  final entry = costs[color];
  final dynamicCost = isDynamicCardCost(entry);
  if (dynamicCost && delta < 0 && !restoring) return 0;
  final base = cardCostBase(entry);
  final updated = math.max(0, base + delta);
  if (dynamicCost) {
    entry['base'] = updated;
  } else {
    costs[color] = updated;
  }
  return updated - base;
}

/// 无副作用的支付计算。paid 以资源状态 id 为键；missing 为需求量与可用量。
/// 动态费用耗尽本色气，太极只补最低门槛缺口；失败时不返回部分支付。
({Map<String, int> paid, Map<String, (int, int)> missing}) calculateCardPayment(
    dynamic costs, Map<String, int> resources,
    {bool wildcardForbidden = false}) {
  final paid = <String, int>{};
  final missing = <String, (int, int)>{};
  var wildcard = resources[kWildcardStatusId] ?? 0;
  if (costs != null) {
    for (final color in costs.keys) {
      final statusId = color == kColorlessCostColorId
          ? 'energy_positive_life'
          : kCostColorStatusIds[color];
      if (statusId == null) continue;
      final entry = costs[color];
      final need = cardCostBase(entry);
      final stock = resources[statusId] ?? 0;
      final canUseWildcard =
          color != kColorlessCostColorId && !wildcardForbidden;
      final available = stock + (canUseWildcard ? wildcard : 0);
      if (need > available) {
        missing[statusId] = (need, available);
        continue;
      }
      final ownPaid = isDynamicCardCost(entry) ? stock : math.min(stock, need);
      final wildcardPaid = math.max(0, need - ownPaid);
      if (ownPaid > 0) paid[statusId] = ownPaid;
      if (wildcardPaid > 0) {
        paid[kWildcardStatusId] = (paid[kWildcardStatusId] ?? 0) + wildcardPaid;
        wildcard -= wildcardPaid;
      }
    }
  }
  return (paid: missing.isEmpty ? paid : <String, int>{}, missing: missing);
}

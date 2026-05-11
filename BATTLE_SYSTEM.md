**玩家回合（heroTurn == true）：**

1. 执行 `currentCharacter.onStartTurn()`
2. 抽牌：`drawCardsToHand()`
3. 等待玩家选择：使用 `_playerCardSelection(Completer<CustomGameCard>)`
4. 玩家点击卡牌 → 验证可打出（资源足够等）→ 执行效果
5. 返回 3
6. 玩家点击回合结束
7. 执行 `currentCharacter.onEndTurn()`
8. `heroHandZone.clearHand()`
9. 切换回合

**敌方回合（heroTurn == false）：**

1. 执行 `currentCharacter.onStartTurn()`
2. 抽牌：`enemyHandZone.drawCards(enemyDeck, enemyDrawCount)`
3. 选择一张牌
4. 自动执行效果
5. 当手牌中还有小于剩余费用的卡牌时，返回 3
6. 执行 `currentCharacter.onEndTurn()`
7. `enemyHandZone.clearHand()`
8. 切换回合

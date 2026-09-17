# 设计笔记（DESIGN NOTE）

## 数据设计规则

### rankIncrement 词条不得出现在天赋树节点上

- 天赋树节点（`characterSetPassive`）不要配置带 `rankIncrement` 的词条：
- 天赋词条的数值在学习/升级时按角色当时境界烘焙，角色升境后不会自动刷新，会产生陈旧的数值；
- 天赋树节点应使用 `increment`（按等级缩放）的词条。

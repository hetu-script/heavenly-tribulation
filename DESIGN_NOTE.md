# 设计笔记（DESIGN NOTE）

## 数据设计规则

### rankIncrement 词条不得出现在天赋树节点上

- 天赋树节点（`characterSetPassive`）不要配置带 `rankIncrement` 的词条。应使用 `increment`（按等级缩放）的词条。

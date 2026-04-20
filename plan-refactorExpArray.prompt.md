### 聚灵阵重设计

**问题**: 打坐获取经验无交互、无挑战，缺乏游戏体验。
**方案**: 改为**战斗buff站**——花费灵光获得临时战斗增益（保存在ephemeralPassives中）。

修炼场景移除 collect/exhaust 模式（保留 daostele），新增exparray 模式：

进入聚灵阵需要花费灵石，即便是development为0时也要至少支付1个灵石。高发展度的需要的灵石更多。

进入修炼场景后，玩家选择 exparray 模式的打坐，类似daostele，通过收集5个光点，点击正确文字，最终获得一个临时buff。此buff类似可以从丹药上获得的buff。但是是直接获得。

exparray的development决定了buff的数量。发展度为0只有一个，最多6个。

每有一个buff需要经历一次收集光点和点击文字的流程。不过和悟道碑不同的是，中途失败退出后仍会保留之前成功的次数对应的buff。

## Plan: 扩展沙盒开局教程

建议继续沿用现有的单主线事项 sandboxTutorial，把新手后半段改成一条连续流程：木人战后引导去会堂接悬赏，完成任意悬赏后解锁斗技场，完成一次斗技场挑战后解锁秘境，进入一次秘境后把事项目标切到“继续升级并突破到凝气”。实现上尽量保持教程逻辑在脚本侧，只在 Dart 入口和结算点补 2 到 3 个通用事件，避免把教程判断散落到 UI 层。

**Steps**

1. 先重排 sandboxTutorial 的阶段定义，扩展 [assets/data/journals.json5](assets/data/journals.json5) 和 [assets/locale/zh/journal/tutorial.json](assets/locale/zh/journal/tutorial.json)，把事项顺序定为：悬赏任务、斗技场、秘境、提升等级并突破到凝气、加入门派。这里要确保 stage 连续，符合 [scripts/main/data/journal.ht](scripts/main/data/journal.ht#L103) 的加载约束。

2. 在 [scripts/main/event/game.ht](scripts/main/event/game.ht) 的 tutorial flags 下补一组新状态，建议至少有 bountyHinted、arenaHinted、dungeonHinted 之类的提示位。

3. 扩展 [scripts/main/event/game.ht](scripts/main/event/game.ht#L16) 的 onAfterEnterLocation，把现有 homeLocation 和 homeSite 教程链继续往后接：木人战胜利后提示去据点会堂接悬赏；玩家完成任意悬赏后，再次进入家乡据点时触发“斗技场修复完成”；斗技场完成后再提示秘境；秘境进入后再切到“提升等级并突破到凝气”的阶段。

4. 在 [scripts/main/event/game.ht](scripts/main/event/game.ht) 新增或补全 onBeforeEnterLocation，通过 location.kind 拦截 arena 和 dungeon。教程开启且未到对应阶段时，直接弹“正在修建/尚未开放”提示并返回 true，作为统一封锁点。

5. 为“完成任意悬赏”补一个通用事件。最稳的做法是在 [scripts/main/event/game.ht](scripts/main/event/game.ht#L139) 现有任务交付成功分支里统一触发一个新 onGameEvent，让教程逻辑只判断 quest 是否属于 bounty，再推进 sandboxTutorial。

6. 为“斗技场挑战完成”补一个通用事件。当前挂点应放在 [lib/logic/location.dart](lib/logic/location.dart) 的斗技场战斗 onBattleEnd 收尾处；无论胜负都发事件，教程脚本收到后推进事项并解锁秘境。

7. 为“进入一次秘境”补一个节点判断。最简单的挂点是 [lib/logic/location.dart](lib/logic/location.dart#L18) 的 \_tryEnterDungeon，在 resetDungeon 完成且即将 push dungeon scene 前更改game.flags的值，教程脚本据此推进。

**Relevant files**

- [scripts/main/event/game.ht](scripts/main/event/game.ht) 用来承接教程主状态机、进入前封锁和任务完成后的推进。
- [scripts/main/event/sandbox.ht](scripts/main/event/sandbox.ht) 用来衔接新游戏初始化和木人战后的下一阶段提示。
- [scripts/main/data/journal.ht](scripts/main/data/journal.ht) 用来约束新的 sandboxTutorial stage 连续性。
- [assets/data/journals.json5](assets/data/journals.json5) 用来扩展 sandboxTutorial 的 endings。
- [assets/locale/zh/journal/tutorial.json](assets/locale/zh/journal/tutorial.json) 用来补事项阶段文案和新教程对白。
- [lib/logic/location.dart](lib/logic/location.dart) 用来补斗技场完成事件、秘境进入事件，并确认起始设施保障链路。
- [scripts/main/event.ht](scripts/main/event.ht#L71) 用来确认新增 onGameEvent 事件名可被统一分发。
- 起始设施相关脚本，优先检查 [scripts/main/world/world.ht](scripts/main/world/world.ht) 是否已经覆盖你要的中立秘境保障。

**Decisions**

- 继续扩展现有 sandboxTutorial，不拆新的事项。
- 秘境教程完成条件按“成功进入一次秘境即可”处理。
- 斗技场和秘境封锁统一用 onBeforeEnterLocation，不改场景 UI 结构。
- 本轮范围只覆盖开局三玩法教程和封锁，不包含后续门派线的完整实现。

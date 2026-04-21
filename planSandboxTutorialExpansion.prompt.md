## Plan: 扩展沙盒开局教程

拓展单主线事项 sandboxTutorial，把新手后半段改成一条连续流程：木人战胜利后提示去据点会堂接悬赏；玩家完成任意悬赏后，再次进入家乡据点时触发“斗技场修复完成”；斗技场完成后再提示秘境；秘境进入后再切到“提升等级并突破到凝气”的阶段。突破到凝气后再提示加入门派。加入门派后再提示参与门派例会领取任务，之后再提示通过积累功勋升级到筑基并积累功勋提升门派职级。目前DEMO先做到这里为止。后续没有更多事项。

**Steps**

1. 在 [scripts/main/event/game.ht](scripts/main/event/game.ht) 新增或补全 onBeforeEnterLocation，通过 location.kind 拦截 arena 和 dungeon。教程开启且未到对应阶段时，直接弹“正在修建/尚未开放”提示并返回 true，阻止玩家进入。

2. “完成任意悬赏后”。挂点在 [scripts/main/event/game.ht](scripts/main/event/game.ht#L139) 现有任务交付成功分支里，此时统一检测并赋值game.tutorial.bountyQuest开关，并推进sandboxTutorial。

3. “斗技场挑战完成后”。挂点在 [lib/logic/location.dart](lib/logic/location.dart) 的斗技场战斗 onBattleEnd 收尾处；无论胜负都发事件，检测并赋值game.tutorial.arena开关，推进事项并解锁秘境。

4. 为“进入一次秘境”补一个节点判断。最简单的挂点是 [lib/logic/location.dart](lib/logic/location.dart#L18) 的 \_tryEnterDungeon，在 resetDungeon 完成且即将 push dungeon scene 前更改game.tutorial.dungeon的值，教程脚本据此推进。

5. 最后，在秘境完成之后，在玩家再次进入家乡据点之后，提示玩家提升等级并尝试突破到凝气境。

6. 当玩家突破凝气境后，设置game.tutorial.rank1，提示玩家可以去加入门派了。

7. 当玩家加入门派后，这里需要新增一个回调事件，因为这个节点比较关键，可能对其他事件或者MOD有用。在这个事件中，加入门派后设置game.tutorial.sect开关，在这之后需要合并目前已有的事项：sectInitiation的内容。

8. 重排 sandboxTutorial 的阶段定义，扩展 [assets/data/journals.json5](assets/data/journals.json5) 和 [assets/locale/zh/journal/tutorial.json](assets/locale/zh/journal/tutorial.json)，把事项顺序定为：悬赏任务、斗技场、秘境、提升等级并突破到凝气、加入门派、参与门派例会、提升职级。这里要确保 stage 连续，符合 [scripts/main/data/journal.ht](scripts/main/data/journal.ht#L103) 的加载约束。之后移除 sectInitiation相关的旧事项。

**Relevant files**

- [scripts/main/event/game.ht](scripts/main/event/game.ht) 用来承接教程主状态机、进入前封锁和任务完成后的推进。
- [scripts/main/data/journal.ht](scripts/main/data/journal.ht) 用来约束新的 sandboxTutorial stage 连续性。
- [assets/data/journals.json5](assets/data/journals.json5) 用来扩展 sandboxTutorial 的 endings。
- [assets/locale/zh/journal/tutorial.json](assets/locale/zh/journal/tutorial.json) 用来补事项阶段文案和新教程对白。
- [lib/logic/location.dart](lib/logic/location.dart) 用来补斗技场完成事件、秘境进入事件，并确认任务完成前封锁设施。

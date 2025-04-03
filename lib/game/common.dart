// 预定义的天赋树节点路线，用于NPC提升等级时自动分配

const kPlayStyles = {
  'dexterity': {'standard'},
  'spirituality': {'standard'},
  'willpower': {'standard'},
  'perception': {'standard'},
  'strength': {'standard'},
};

/// 不同流派的境界节点路径
const kCultivationRankPaths = {
  'dexterity': [
    'track_5_0',
    'track_6_0',
    'track_7_0',
    'track_8_0',
    'track_9_0',
    'track_10_0',
    'track_11_0',
    'track_12_0',
  ],
  'spirituality': [
    'track_5_4',
    'track_6_8',
    'track_7_4',
    'track_8_8',
    'track_9_4',
    'track_10_8',
    'track_11_4',
    'track_12_8',
  ],
  'willpower': [
    'track_5_8',
    'track_6_16',
    'track_7_8',
    'track_8_16',
    'track_9_8',
    'track_10_16',
    'track_11_8',
    'track_12_16',
  ],
  'perception': [
    'track_5_12',
    'track_6_24',
    'track_7_12',
    'track_8_24',
    'track_9_12',
    'track_10_24',
    'track_11_12',
    'track_12_24',
  ],
  'strength': [
    'track_5_16',
    'track_6_32',
    'track_7_16',
    'track_8_32',
    'track_9_16',
    'track_10_32',
    'track_11_16',
    'track_12_32',
  ],
};

const kCultivationStylePaths = {
  'dexterity': {
    'standard': [
      'track_0_0',
      'track_1_0',
      'track_2_0',
      'track_3_0',
      'track_4_0', // 以上5个节点是境界前置必须
      'track_2_9',
      'track_3_9',
      'track_4_18', // 身法+20
      'track_2_1',
      'track_3_1',
      'track_4_2', // 灵力+20
      'track_4_19',
      'track_5_19',
      'track_6_38',
      'track_6_37', // 武器攻
      'track_4_3',
      'track_5_3',
      'track_6_6',
      'track_6_5', // 法攻
      'track_4_1',
      'track_5_1',
      'track_6_2',
      'track_6_3', // 速度
      'track_4_17',
      'track_5_17',
      'track_6_34',
      'track_6_35', // 物抗
      'track_5_18',
      'track_6_36',
      'track_7_18',
      'track_8_36', // 身法+20
      'track_9_18', // 战斗开始时剑气
      'track_5_2',
      'track_6_4',
      'track_7_2',
      'track_8_4', // 灵力+20
      'track_9_2', // 战斗开始时灵气
      'track_8_5',
      'track_8_6',
      'track_8_7',
      'track_6_7', // 灵气不足时自动恢复
      'track_8_3',
      'track_8_2',
      'track_8_1',
      'track_6_1', // 灵气视作剑气
      'track_8_37',
      'track_8_38',
      'track_8_39',
      'track_6_39', // 无需装备剑
      'track_8_35',
      'track_8_34',
      'track_8_33',
      'track_6_33', // 剑气溢出的debuff变双方
    ],
  },
  'spirituality': {
    'standard': [
      'track_0_1',
      'track_1_1',
      'track_2_2',
      'track_3_2',
      'track_4_4', // 以上5个节点是境界前置必须
      'track_2_1',
      'track_3_1',
      'track_4_2', // 灵力+20
      'track_2_3',
      'track_3_3',
      'track_4_6', // 神识+20
      'track_4_3',
      'track_5_3',
      'track_6_6',
      'track_6_5', // 法攻
      'track_4_1',
      'track_5_1',
      'track_6_2',
      'track_6_3', // 速度
      'track_4_5',
      'track_5_5',
      'track_6_10',
      'track_6_11', // 元素抗
      'track_4_7',
      'track_5_7',
      'track_6_14',
      'track_6_13', // 真气抗
      'track_5_2',
      'track_6_4',
      'track_7_2',
      'track_8_4', // 灵力+20
      'track_9_2', // 战斗开始时灵气
      'track_5_6',
      'track_6_12',
      'track_7_6',
      'track_8_12', // 神识+20
      'track_9_6', // 战斗开始时元气
      'track_8_5',
      'track_8_6',
      'track_8_7',
      'track_6_7', // 灵气不足时自动恢复
      'track_8_11',
      'track_8_10',
      'track_8_9',
      'track_6_9', // 灵气溢出转化为元气
      'track_8_13',
      'track_8_14',
      'track_8_15',
      'track_6_15', // ---
      'track_8_3',
      'track_8_2',
      'track_8_1',
      'track_6_1', // 灵气视作剑气
    ],
  },
  'willpower': {
    'standard': [
      'track_0_2',
      'track_1_2',
      'track_2_4',
      'track_3_4',
      'track_4_8', // 以上5个节点是境界前置必须
      'track_2_5',
      'track_3_5',
      'track_4_10', // 念力+20
      'track_2_3',
      'track_3_3',
      'track_4_6', // 神识+20
      'track_4_11',
      'track_5_11',
      'track_6_22',
      'track_6_21', // 咒攻
      'track_4_5',
      'track_5_5',
      'track_6_10',
      'track_6_11', // 元素抗
      'track_4_7',
      'track_5_7',
      'track_6_14',
      'track_6_13', // 真气抗
      'track_4_9',
      'track_5_9',
      'track_6_18',
      'track_6_19', // 精神抗
      'track_5_10',
      'track_6_20',
      'track_7_10',
      'track_8_20', // 念力+20
      'track_9_10', // 战斗开始时辟邪
      'track_5_6',
      'track_6_12',
      'track_7_6',
      'track_8_12', // 神识+20
      'track_9_6', // 战斗开始时元气
      'track_8_19',
      'track_8_18',
      'track_8_17',
      'track_6_17', // 咒术造成纯粹伤害
      'track_8_11',
      'track_8_10',
      'track_8_9',
      'track_6_9', // 灵气溢出转化为元气
      'track_8_13',
      'track_8_14',
      'track_8_15',
      'track_6_15', // ---
      'track_8_21',
      'track_8_22',
      'track_8_23',
      'track_6_23', // ---
    ],
  },
  'perception': {
    'standard': [
      'track_0_3',
      'track_1_3',
      'track_2_6',
      'track_3_6',
      'track_4_12', // 以上5个节点是境界前置必须
      'track_2_5',
      'track_3_5',
      'track_4_10', // 念力+20
      'track_2_7',
      'track_3_7',
      'track_4_14', // 体魄+20
      'track_4_15',
      'track_5_15',
      'track_6_30',
      'track_6_29', // 徒手攻
      'track_4_11',
      'track_5_11',
      'track_6_22',
      'track_6_21', // 咒攻
      'track_4_13',
      'track_5_13',
      'track_6_26',
      'track_6_27', // 闪避
      'track_4_9',
      'track_5_9',
      'track_6_18',
      'track_6_19', // 精神抗
      'track_5_10',
      'track_6_20',
      'track_7_10',
      'track_8_20', // 念力+20
      'track_9_10', // 战斗开始时辟邪
      'track_5_14',
      'track_6_28',
      'track_7_14',
      'track_8_28', // 体魄+20
      'track_9_14', // 战斗开始时怒气
      'track_8_19',
      'track_8_18',
      'track_8_17',
      'track_6_17', // 咒术造成纯粹伤害
      'track_8_29',
      'track_8_30',
      'track_8_31',
      'track_6_31', // 怒气不足时消耗生命
      'track_8_21',
      'track_8_22',
      'track_8_23',
      'track_6_23', // ---
      'track_8_27',
      'track_8_26',
      'track_8_25',
      'track_6_25', // ---
    ],
  },
  'strength': {
    'standard': [
      'track_0_4',
      'track_1_4',
      'track_2_8',
      'track_3_8',
      'track_4_16', // 以上5个节点是境界前置必须
      'track_2_7',
      'track_3_7',
      'track_4_14', // 体魄+20
      'track_2_9',
      'track_3_9',
      'track_4_18', // 身法+20
      'track_4_15',
      'track_5_15',
      'track_6_30',
      'track_6_29', // 徒手攻
      'track_4_19',
      'track_5_19',
      'track_6_38',
      'track_6_37', // 武器攻
      'track_4_13',
      'track_5_13',
      'track_6_26',
      'track_6_27', // 闪避
      'track_4_17',
      'track_5_17',
      'track_6_34',
      'track_6_35', // 物抗
      'track_5_14',
      'track_6_28',
      'track_7_14',
      'track_8_28', // 体魄+20
      'track_9_14', // 战斗开始时怒气
      'track_5_18',
      'track_6_36',
      'track_7_18',
      'track_8_36', // 身法+20
      'track_9_18', // 战斗开始时剑气
      'track_8_29',
      'track_8_30',
      'track_8_31',
      'track_6_31', // 怒气不足时消耗生命
      'track_8_35',
      'track_8_34',
      'track_8_33',
      'track_6_33', // 剑气溢出的debuff变双方
      'track_8_37',
      'track_8_38',
      'track_8_39',
      'track_6_39', // 无需装备剑
      'track_8_27',
      'track_8_26',
      'track_8_25',
      'track_6_25', // ---
    ],
  },
};

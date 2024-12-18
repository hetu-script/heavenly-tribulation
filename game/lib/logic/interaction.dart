import '../config.dart';
import '../data.dart';
import '../dialog/game_dialog/game_dialog.dart';

/// 返回一个表示是否终止移动的布尔值，如果为 true，则玩家控制角色会返回上一格，false 则停止移动并留在在这一格，null 则不影响
bool? movableTest(left, top) {
  // engine.info('玩家移动到了: ${left}, ${top}')
  final terrain = engine.hetu
      .invoke('getTerrainByWorldPosition', positionalArgs: [left, top]);
  if (terrain['isNonInteractable'] == true) {
    GameDialog.show(context: GameData.ctx!, dialogData: {
      'lines': [engine.locale('hint.nonInteractableTile')]
    });
    return true;
  }
  return null;
}

import os

os.system(
    'hetu compile packages/game/scripts/game/main.ht -o packages/game/assets/game.mod')

os.system(
    'hetu compile packages/game/scripts/core/main.ht -o packages/game/assets/mod.mod')

import os

version = '0.1.0-pre29'

dir_list = os.listdir('packages/game/scripts')

for dir_name in dir_list:
    os.system(
        f'hetu compile packages/game/scripts/{dir_name}/main.ht packages/game/assets/mods/{dir_name}.mod -v "{version}"')

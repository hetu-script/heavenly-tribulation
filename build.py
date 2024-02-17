import os

version = '0.1.0-pre30'

dir_list = os.listdir('game/scripts')

for dir_name in dir_list:
    os.system(
        f'hetu compile game/scripts/{dir_name}/main.ht game/assets/mods/{dir_name}.mod -v "{version}"')

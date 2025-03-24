import os

dir_list = os.listdir('scripts')

for dir_name in dir_list:
    if not dir_name.startswith('_'):
        os.system(f'hetu compile scripts/{dir_name}/main.ht assets/mods/{dir_name}.mod')

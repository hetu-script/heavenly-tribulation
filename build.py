import os
import shutil
import subprocess

hetu = shutil.which('hetu') or shutil.which('hetu.bat')
if hetu is None:
    raise FileNotFoundError('找不到 Hetu CLI，请先通过 dart install 安装')

dir_list = os.listdir('scripts')

for dir_name in dir_list:
    if not dir_name.startswith('_'):
        subprocess.run(
            [
                hetu,
                'compile',
                f'scripts/{dir_name}/main.ht',
                f'assets/mods/{dir_name}.mod',
            ],
            check=True,
        )

# os.system('flutter build windows')
#!/usr/bin/env python3

## -- BEGIN PORTMASTER INFO --
PORTMASTER_VERSION = '2024.04.10-1237'
PORTMASTER_RELEASE_CHANNEL = 'beta'
## -- END PORTMASTER INFO --

PORTMASTER_MIN_VERSION = '2024-04-06-0000'
PORTMASTER_RELEASE_URL = 'https://github.com/PortsMaster/PortMaster-GUI/releases/latest/download/'
PORTMASTER_RELEASE_VALUES = ('stable', 'beta', 'alpha')

PORTMASTER_UPDATE_FREQUENCY = (60 * 60 * 1)
__builtins__.PORTMASTER_DEBUG = False  ## This adds a lot of extra info

import contextlib
import ctypes
import datetime
import errno
import functools
import gettext
import hashlib
import json
import math
import os
import re
import shutil
import sys
import tarfile
import textwrap
import time
import zipfile

from pathlib import Path

################################################################################
## Insert our extra modules.
PYLIB_PATH    = Path(__file__).parent / 'pylibs'
EXLIB_PATH    = Path(__file__).parent / 'exlibs'
PYLIB_ZIP     = Path(__file__).parent / 'pylibs.zip'
PYLIB_ZIP_MD5 = Path(__file__).parent / 'pylibs.zip.md5'

if not (Path(__file__).parent / '.git').is_dir() and not (Path(__file__).parent / '..' / '.git').is_dir():
    if PYLIB_ZIP.is_file():
        if PYLIB_PATH.is_dir():
            print("- removing old pylibs.")
            shutil.rmtree(PYLIB_PATH)

        if EXLIB_PATH.is_dir():
            print("- removing old exlibs.")
            shutil.rmtree(EXLIB_PATH)

        print("- extracting new pylibs.")
        with zipfile.ZipFile(PYLIB_ZIP, 'r') as zf:
            zf.extractall(Path(__file__).parent)

        md5_check = hashlib.md5()
        with PYLIB_ZIP.open('rb') as fh:
            while True:
                data = fh.read(1024 * 1024)
                if len(data) == 0:
                    break

                md5_check.update(data)

        with PYLIB_ZIP_MD5.open('wt') as fh:
            fh.write(md5_check.hexdigest())

        print("- recorded pylibs.zip.md5")

        del md5_check

        print("- removing pylibs.zip")
        PYLIB_ZIP.unlink()


if not (PYLIB_PATH / 'resources' / 'NotoSansTC-Regular.ttf').is_file():
    ## Extract Noto fonts.
    with tarfile.open(str(PYLIB_PATH / 'resources' / 'NotoSans.tar.xz'), 'r:xz') as tar:
        # Extract all contents into the specified directory
        tar.extractall(str(PYLIB_PATH / 'resources'))


## HACK D:
__builtins__.PYLIB_PATH = PYLIB_PATH

sys.path.insert(0, str(EXLIB_PATH))
sys.path.insert(0, str(PYLIB_PATH))

################################################################################
## Now load the stuff we include
import utility
import harbourmaster
import png
import requests

import sdl2
import sdl2.ext

import pySDL2gui
import pugtheme

from loguru import logger
from pugtheme import theme_load, ThemeEngine, ThemeDownloader
from pugscene import *

from harbourmaster import (
    HarbourMaster,
    make_temp_directory,
    )

_ = gettext.gettext




print("This line will be printed=====================================================================================.")



# Initialisation de SDL
sdl2.ext.init()

# Création de la fenêtre
window_width, window_height = 300, 200
window = sdl2.ext.Window("Interface avec une case à cocher", size=(window_width, window_height))
window.show()

# Création du rendu
renderer = sdl2.ext.Renderer(window)

# Création de la case à cocher
checkbox_rect = sdl2.SDL_Rect(50, 50, 30, 30)
checkbox_checked = False

# Boucle principale
running = True
while running:
    # Gestion des événements
    events = sdl2.ext.get_events()
    for event in events:
        if event.type == sdl2.SDL_QUIT:
            running = False
            break
        elif event.type == sdl2.SDL_KEYDOWN:
            # Inverser l'état de la case à cocher
            if event.key.keysym.sym == sdl2.SDLK_SPACE:
                checkbox_checked = not checkbox_checked

    # Effacer l'écran
    renderer.clear()

    # Dessiner la case à cocher
    renderer.fill(checkbox_rect, sdl2.ext.Color(255, 255, 255))
    if checkbox_checked:
        renderer.draw_rect(checkbox_rect, sdl2.ext.Color(0, 0, 0))

    # Afficher le rendu
    renderer.present()

# Fermeture de la fenêtre et de SDL
sdl2.ext.quit()
#!/usr/bin/env python3

import os
import sys
import shutil
import argparse
import json


from simple_term_menu import TerminalMenu


def get_files(folder):
    files = []
    for root, dirs, file in os.walk(folder):
        for f in file:
            if not f.startswith("."):
                lin_path = os.path.join(root, f).replace(os.sep, "/")
                linux_path = "/mnt/SDCARD/Roms/" + lin_path
                files.append(linux_path)
    return files

def add_selected_files(folder):
    folder_files = get_files(folder)
    terminal_menu = TerminalMenu(folder_files,
        multi_select=True,
        show_multi_select_hint=True)
    selected_files = terminal_menu.show()
    if selected_files is None:
        return []
    return [folder_files[index] for index in selected_files]


def get_selected_folders():
    folders = []
    for root, dirs, file in os.walk("."):
        folders = dirs
        break

    terminal_menu = TerminalMenu(folders,
        multi_select=True,
        show_multi_select_hint=True)
    selected_folders = terminal_menu.show()
    if selected_folders is None:
        return []
    return [folders[index] for index in selected_folders]

def create_collection_dir(collection_name):
    if os.path.exists(collection_name):
        overwrite = input("Collection already exists. Overwrite? (y/n): ")
        if overwrite.lower() == "y":
            shutil.rmtree(collection_name)
            os.mkdir(collection_name)
        else:
            print("Exiting without overwriting.")
            sys.exit()
    else:
        os.mkdir(collection_name)
    os.chdir(collection_name)
    os.mkdir("Roms")
    os.mkdir("Imgs")
    script_dir = os.path.dirname(os.path.realpath(__file__))
    shutil.copyfile(os.path.join(script_dir, "collection_launcher.sh"), "launch.sh" )
    config=os.path.join(script_dir, "collection_config.json")
    with open(config, 'r') as file:
        data = json.load(file)
    data["label"] = collection_name
    with open('config.json', 'w') as file:
        json.dump(data, file, indent=4)

def main():
    parser = argparse.ArgumentParser(description="Create a collection of ROM files.")
    parser.add_argument("Roms_dir", type=str, help="Directory containing the ROMs.")
    parser.add_argument("Collection_dir", type=str, help="Directory to store the collection.")
    args = parser.parse_args()
    # check if the user has provided the path to the roms directory
    roms_dir = os.path.realpath(args.Roms_dir)
    coll_dir = os.path.realpath(args.Collection_dir)


    os.chdir(coll_dir)
    collection_name = input("Enter the collection name: ")
    create_collection_dir(collection_name)
    collection_path = os.path.join(coll_dir, collection_name)

    os.chdir(roms_dir)
    folders = get_selected_folders()
    if not folders:
        print("No folders selected. Exiting.")
        sys.exit()

    for folder in folders:
        os.chdir(roms_dir)
        files = add_selected_files(folder)
        if not files:
            continue
        roms_path = os.path.join(collection_path, "Roms")
        os.chdir(roms_path)
        os.mkdir(folder)
        os.chdir(folder)
        for file in files:
            filename = os.path.basename(file)
            filename_txt = os.path.splitext(filename)[0] + ".txt"
            with open(filename_txt, "w") as f:
                f.write(file)
    print("Collection created")

if __name__ == "__main__":
    main()

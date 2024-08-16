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
    files_names = [os.path.basename(file) for file in folder_files]
    terminal_menu = TerminalMenu(files_names,
        multi_select=True,
        show_multi_select_hint=True)
    selected_files = terminal_menu.show()
    if selected_files is None:
        return []
    return [folder_files[index] for index in selected_files]


def listdir_nohidden(path):
    for f in os.listdir(path):
        if not f.startswith('.'):
            yield f

def get_selected_folders():
    all_folders = []
    for root, dirs, file in os.walk("."):
        all_folders = dirs
        break
    folders = [folder for folder in all_folders if listdir_nohidden(folder)]


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
    parser.add_argument("Imgs_dir", type=str, help="Directory containing the images.")
    parser.add_argument("Collection_dir", type=str, help="Directory to store the collection.")
    args = parser.parse_args()
    # check if the user has provided the path to the roms directory
    roms_dir = os.path.realpath(args.Roms_dir)
    imgs_dir = os.path.realpath(args.Imgs_dir)
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

    dest_imgs_path = os.path.join(collection_path, "Imgs")
    for folder in folders:
        os.chdir(roms_dir)
        files = add_selected_files(folder)
        if not files:
            continue
        dest_roms_path = os.path.join(collection_path, "Roms", folder)
        os.mkdir(dest_roms_path)
        os.chdir(dest_roms_path)
        for file in files:
            filename = os.path.basename(file)
            basename = os.path.splitext(filename)[0]
            with open(os.path.join(dest_roms_path, basename + ".txt"), "w") as f:
                f.write(file)
            src_img = os.path.join(imgs_dir, folder, basename + ".png")
            if os.path.exists(src_img): 
                shutil.copyfile(src_img, os.path.join(dest_imgs_path, basename + ".png"))
    print("Collection created")

if __name__ == "__main__":
    main()

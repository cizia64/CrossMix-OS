#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dirent.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <stdbool.h>
#include <ctype.h>
#include <limits.h>
#include <libgen.h>

#define MAX_PATH 1024
#define MAX_LINE 4096

// Helper to check if a file exists
bool file_exists(const char *path) {
    return access(path, F_OK) == 0;
}

// Simple JSON string extractor (very basic, assumes no escaped quotes inside string for simplicity or handles them minimally)
// Returns a newly allocated string that must be freed.
char *get_json_value(const char *json, const char *key) {
    char search_key[256];
    snprintf(search_key, sizeof(search_key), "\"%s\"", key);
    
    char *pos = strstr(json, search_key);
    if (!pos) return NULL;

    // Move past key
    pos += strlen(search_key);
    
    // Find colon
    pos = strchr(pos, ':');
    if (!pos) return NULL;
    pos++;

    // Skip whitespace
    while (*pos && isspace((unsigned char)*pos)) pos++;

    if (*pos == '"') {
        // String value
        pos++;
        char *end = pos;
        while (*end && *end != '"') {
            if (*end == '\\' && *(end+1)) end++; // Skip escaped char
            end++;
        }
        size_t len = end - pos;
        char *val = malloc(len + 1);
        strncpy(val, pos, len);
        val[len] = '\0';
        return val;
    } else {
        // null or other types (we mainly care about strings here, but extlist can be null)
        if (strncmp(pos, "null", 4) == 0) return NULL;
        // For now, we only implement string extraction as per requirement
        return NULL;
    }
}

// Check if file has one of the extensions
bool has_extension(const char *filename, const char *extlist) {
    if (!extlist || strlen(extlist) == 0) return true; // If no extlist, assume all files (except excluded ones)

    const char *dot = strrchr(filename, '.');
    if (!dot) return false;
    dot++; // Skip dot

    // extlist is "zip|7z|rar"
    char *list_copy = strdup(extlist);
    char *token = strtok(list_copy, "|");
    while (token) {
        if (strcasecmp(dot, token) == 0) {
            free(list_copy);
            return true;
        }
        token = strtok(NULL, "|");
    }
    free(list_copy);
    return false;
}

// Recursive search for ROMs
// depth: current depth (starts at 1)
// max_depth: 2
bool find_roms(const char *base_path, const char *extlist, int depth, int max_depth) {
    if (depth > max_depth) return false;

    DIR *dir = opendir(base_path);
    if (!dir) return false;

    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) continue;

        char path[MAX_PATH];
        snprintf(path, sizeof(path), "%s/%s", base_path, entry->d_name);

        struct stat statbuf;
        if (stat(path, &statbuf) != 0) continue;

        if (S_ISDIR(statbuf.st_mode)) {
            if (find_roms(path, extlist, depth + 1, max_depth)) {
                closedir(dir);
                return true;
            }
        } else if (S_ISREG(statbuf.st_mode)) {
            // Check exclusions
            if (strcmp(entry->d_name, ".gitkeep") == 0) continue;
            const char *ext = strrchr(entry->d_name, '.');
            if (ext) {
                if (strcmp(ext, ".db") == 0) continue;
                if (strcmp(ext, ".launch") == 0) continue;
            }

            // Check extensions
            if (extlist == NULL || has_extension(entry->d_name, extlist)) {
                closedir(dir);
                return true;
            }
        }
    }

    closedir(dir);
    return false;
}

int main(void) {
    const char *emu_folder = "/mnt/SDCARD/Emus";

    DIR *dir = opendir(emu_folder);
    if (!dir) return 1;

    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        if (entry->d_type != DT_DIR) continue;
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) continue;

        char subfolder_path[MAX_PATH];
        snprintf(subfolder_path, sizeof(subfolder_path), "%s/%s", emu_folder, entry->d_name);

        char config_path[MAX_PATH];
        snprintf(config_path, sizeof(config_path), "%s/config.json", subfolder_path);
        if (!file_exists(config_path)) continue;

        FILE *file = fopen(config_path, "r");
        if (!file) continue;

        fseek(file, 0, SEEK_END);
        long file_size = ftell(file);
        fseek(file, 0, SEEK_SET);
        if (file_size < 0) {
            fclose(file);
            continue;
        }

        char *config_content = malloc((size_t)file_size + 1);
        if (!config_content) {
            fclose(file);
            continue;
        }
        fread(config_content, 1, (size_t)file_size, file);
        config_content[file_size] = '\0';
        fclose(file);

        char *rompath = get_json_value(config_content, "rompath");
        char *extlist = get_json_value(config_content, "extlist");
        free(config_content);

        char abs_rompath[MAX_PATH];
        if (rompath && rompath[0] == '/') {
            snprintf(abs_rompath, sizeof(abs_rompath), "%s", rompath);
        } else if (rompath) {
            char temp_path[MAX_PATH];
            snprintf(temp_path, sizeof(temp_path), "%s/%s", subfolder_path, rompath);
            if (!realpath(temp_path, abs_rompath)) {
                snprintf(abs_rompath, sizeof(abs_rompath), "%s", temp_path);
            }
        } else {
            snprintf(abs_rompath, sizeof(abs_rompath), "%s", subfolder_path);
        }

        if (!find_roms(abs_rompath, extlist, 1, 2)) {
            char cache_file[MAX_PATH];
            snprintf(cache_file, sizeof(cache_file), "%s/%s_cache7.db", abs_rompath, entry->d_name);
            if (unlink(cache_file) == 0) {
                printf("Removed cache: %s\n", cache_file);
            }
        }

        free(rompath);
        free(extlist);
    }

    closedir(dir);

    return 0;
}

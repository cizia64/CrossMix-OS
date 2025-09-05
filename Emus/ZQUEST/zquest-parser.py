# purezc - ZQuest parser by Cizia
import urllib.request
import ssl
import re
import os
import subprocess

# URLs to scrape with their associated output directory
URLS = [
    ("https://www.purezc.net/index.php?page=quests&version=2.10&sort=hits", "/mnt/SDCARD/Roms/ZQUEST/Greatest Hits"),
    ("https://www.purezc.net/index.php?page=quests&version=2.10&sort=rating", "/mnt/SDCARD/Roms/ZQUEST/Best Rating"),
    ("https://www.purezc.net/index.php?page=quests&version=2.10&sort=updated", "/mnt/SDCARD/Roms/ZQUEST/Recently Updated"),
    ("https://www.purezc.net/index.php?page=quests&version=2.10&sort=added", "/mnt/SDCARD/Roms/ZQUEST/Recently Added")
]

cafile = "/etc/ssl/certs/ca-certificates.crt"
img_dir = "/mnt/SDCARD/Imgs/ZQUEST/"
font_path = "/mnt/SDCARD/System/resources/DejaVuSans.ttf"
convert_bin = "/mnt/SDCARD/System/bin/convert"

os.makedirs(img_dir, exist_ok=True)
ctx = ssl.create_default_context(cafile=cafile)

def download_with_wget(url, output_path):
    try:
        result = subprocess.call([
            "wget", "--no-check-certificate", "-q", "-O", output_path, url
        ])
        return result == 0
    except Exception as e:
        print("[ERROR] wget:", e)
        return False

def sanitize_filename(name):
    return "".join(c for c in name if c.isalnum() or c in (' ', '_', '-')).rstrip()

def rating_to_stars(rating):
    try:
        val = float(rating)
        full = int(round(val))
        return "★" * full + "☆" * (5 - full)
    except:
        return "N/A"

def resolve_download_link(intermediate_url):
    try:
        result = subprocess.run([
            "wget", "--max-redirect=10", "--server-response", "--spider", intermediate_url
        ], capture_output=True, text=True, check=True)

        locations = [line.strip() for line in result.stderr.splitlines() if "Location:" in line]
        if not locations:
            print("[ERROR] No Location header found.")
            return None

        relative_path = locations[-1].split("Location:")[1].strip().split()[0]

        if relative_path.startswith("http"):
            return relative_path
        else:
            return "https://www.purezc.net/" + relative_path

    except subprocess.CalledProcessError as e:
        print("[ERROR] wget spider failed:", e)
    except Exception as e:
        print("[ERROR] Exception in resolve_download_link:", e)

    return None

# Process each quest list URL
for url, rom_dir in URLS:
    print(f"\n=== Processing: {url} ===")
    os.makedirs(rom_dir, exist_ok=True)

    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    response = urllib.request.urlopen(req, context=ctx)
    html = response.read().decode('utf-8')

    quest_pattern = r'(<tr[^>]*>\s*<td[^>]*class="row2"[^>]*>.*?</tr>)\s*(<tr[^>]*>.*?</tr>)'
    quest_pairs = re.findall(quest_pattern, html, re.S)
    print(f"→ {len(quest_pairs)} quests found")

    for title_row, detail_row in quest_pairs:
        q = title_row + detail_row

        id_match = re.search(r'index\.php\?page=quests&id=(\d+)', q)
        quest_id = id_match.group(1) if id_match else "N/A"

        title_match = re.search(r'<a href="index\.php\?page=quests&id=\d+">([^<]+)</a>', title_row)
        title = title_match.group(1).strip() if title_match else f"Quest_{quest_id}"
        title_safe = sanitize_filename(title)

        author_match = re.search(r'by\s*(?:<[^>]*>)*\s*([^\s<>\n]+)', title_row, re.S)
        author = author_match.group(1).strip() if author_match else "N/A"

        img_match = re.search(r'<img src=[\'"]([^\'"]+\.gif)[\'"]', detail_row)
        screenshot_url = "https://www.purezc.net" + img_match.group(1) if img_match else "N/A"

        genre_match = re.search(r'<strong>Genre:</strong>\s*<a[^>]*>([^<]+)</a>', detail_row)
        genre = genre_match.group(1) if genre_match else "N/A"

        updated_match = re.search(r'<strong>Updated:</strong>\s*([^<]+)<', detail_row)
        updated = updated_match.group(1).strip() if updated_match else "N/A"

        posted_match = re.search(r'<strong>Posted:</strong>\s*([^<]+)<', detail_row)
        posted = posted_match.group(1).strip() if posted_match else "N/A"

        version_match = re.search(r'<strong>ZC Version:</strong>\s*<a[^>]*>([^<]+)</a>', detail_row)
        version = version_match.group(1) if version_match else "N/A"

        rating_match = re.search(r"data-rating='([^']+)'", detail_row)
        rating = rating_match.group(1) if rating_match else "N/A"
        stars = rating_to_stars(rating)

        desc_match = re.search(r'<strong>Information:</strong><br>(.*?)</span>', detail_row, re.S)
        description = desc_match.group(1).strip() if desc_match else "N/A"
        description = re.sub(r'<[^>]+>', '', description)

        intermediate_url = f"https://www.purezc.net/index.php?page=download&section=Quests&id={quest_id}"
        resolved_link = resolve_download_link(intermediate_url)

        print("-" * 50)
        print("ID:", quest_id)
        print("Title:", title)
        print("Author:", author)
        print("Genre:", genre)
        print("Updated:", updated)
        print("Posted:", posted)
        print("Version ZC:", version)
        print("Rating:", rating)
        print("Screenshot:", screenshot_url)
        print("Download URL:", resolved_link)
        print("Description:", description)

        # Convert screenshot to PNG with rating
        if screenshot_url != "N/A" and not screenshot_url.endswith("noshot.gif"):
            gif_path = os.path.join(img_dir, title_safe + ".gif")
            png_path = os.path.join(img_dir, title_safe + ".png")

            if os.path.exists(png_path):
                print("⏩ PNG already exists:", png_path)
            else:
                if download_with_wget(screenshot_url, gif_path):
                    subprocess.call([
                        convert_bin, gif_path,
                        "-gravity", "South",
                        "-background", "#222",
                        "-splice", "0x24",
                        "-fill", "white",
                        "-pointsize", "14",
                        "-font", font_path,
                        "-annotate", "+35+5", "Rating:",
                        "-fill", "#FFA500",
                        "-annotate", "+95+5", stars,
                        png_path
                    ])
                    print("✔ PNG created:", png_path)
                    os.remove(gif_path)
                else:
                    print("[ERROR] Screenshot download failed.")

        # Download .zip quest file
        zip_path = os.path.join(rom_dir, f"{title_safe}.zip")
        if os.path.exists(zip_path):
            print("⏩ Quest already exists:", zip_path)
        else:
            if resolved_link and download_with_wget(resolved_link, zip_path):
                print("✔ Quest downloaded:", zip_path)

                # Show OSD notification on TrimUI
                if os.path.exists(png_path):
                    osd_msg = (
                        f'echo -e \'{{ "duration":2000, "x":920, "y":330, "message":" ", "font":"", '
                        f'"icon":"{png_path}", "fontsize":24 }}\' > /tmp/trimui_osd/osd_toast_msg'
                    )
                    os.system(osd_msg)
            else:
                print("[ERROR] Quest download failed:", resolved_link)

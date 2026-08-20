import json
import os

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def generate_patch(ref_data, target_data):
    patch = {}
    for key, value in target_data.items():
        if key.isdigit():
            key_int = int(key)
            if key_int >= 197:
                # Include all keys >= 197 to ensure full state restoration
                patch[key] = value
    return patch

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    ref_dir = os.path.join(base_dir, 'reference')
    
    if not os.path.exists(ref_dir):
        print(f"Reference directory not found: {ref_dir}")
        return

    # Map folders to device suffix
    targets = [
        ('stock_tg3040', 'brick'),
        ('stock_tg5040', 'tsp'),
        ('stock_tg5050', 'tsps'),
        ('stock_tg4040', 'brickpro')
    ]

    # Create patches directory if it doesn't exist
    patches_dir = os.path.join(base_dir, 'patches')
    if not os.path.exists(patches_dir):
        os.makedirs(patches_dir)

    # Iterate over all .lang files in reference directory
    for filename in os.listdir(ref_dir):
        if not filename.endswith('.lang'):
            continue
            
        lang_code = os.path.splitext(filename)[0]
        ref_path = os.path.join(ref_dir, filename)
        
        try:
            ref_data = load_json(ref_path)
        except Exception as e:
            print(f"Error loading reference {filename}: {e}")
            continue

        print(f"Processing language: {lang_code}")

        for folder, device_suffix in targets:
            target_path = os.path.join(base_dir, folder, filename)
            output_name = f"{lang_code}.{device_suffix}.patch"
            
            if os.path.exists(target_path):
                try:
                    target_data = load_json(target_path)
                    patch = generate_patch(ref_data, target_data)
                    
                    output_path = os.path.join(patches_dir, output_name)
                    with open(output_path, 'w', encoding='utf-8', newline='\n') as f:
                        json.dump(patch, f, indent=4, ensure_ascii=False)
                    print(f"  Created {output_name} with {len(patch)} entries.")
                except Exception as e:
                    print(f"  Error processing {target_path}: {e}")
            else:
                print(f"  Target file not found: {target_path}")

if __name__ == '__main__':
    main()

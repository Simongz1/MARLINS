from pathlib import Path

from PIL import Image

#regular expression to match for plotting

ref = input('Provide the matching name for images to crop: ').strip()
prop = input('Provide the property to plot: ').strip()
use_up = input('Use up naming convention? (YES) (NO)')

if (use_up == "YES"):
    up = input('Provide up value: ')

image_dir = Path(f'DIR{ref}{"_up" + str(up) if use_up == "YES" else ""}')
file_list = sorted(image_dir.glob(f'{ref}{"_up" + str(up) if use_up == "YES" else ""}_{prop}*.png'))

if not file_list:
    raise FileNotFoundError(
        f'No images matched {image_dir / (ref + "_" + prop + "*.png")}'
    )

#define dimensions
crop_box = (770 - 20 if use_up == "YES" else 0, 25, 1920 - 770 + 20 if use_up == "YES" else 0, 1080 - 25)

for image_path in file_list:
    #sanity check
    print(f'Current image: {image_path.name}')

    output_path = image_dir / f'cropped_{image_path.name}'
    with Image.open(image_path) as img:
        cropped = img.crop(crop_box)
        cropped.save(output_path)

    print(f'Saved cropped image: {output_path}')

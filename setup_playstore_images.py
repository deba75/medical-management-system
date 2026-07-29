from PIL import Image
import os
import shutil

# Define icon sizes for each Android density
densities = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

base_path = 'android/app/src/main/res'

# Read the 512x512 image
icon_img = Image.open('512x512.png').convert('RGBA')

# Scale and save to each density folder
for density, size in densities.items():
    folder_path = os.path.join(base_path, density)
    resized_img = icon_img.resize((size, size), Image.Resampling.LANCZOS)
    output_path = os.path.join(folder_path, 'ic_launcher.png')
    resized_img.save(output_path, 'PNG')
    print(f"✓ Created {output_path} ({size}x{size})")

# Create playstore_assets folder for feature graphic and other Play Store assets
playstore_assets_path = 'playstore_assets'
os.makedirs(playstore_assets_path, exist_ok=True)

# Copy feature graphic (1024x500)
shutil.copy('1024x500.png', os.path.join(playstore_assets_path, 'feature_graphic_1024x500.png'))
print(f"✓ Created playstore_assets/feature_graphic_1024x500.png")

print("\n✅ All images successfully placed for Play Store publishing!")

import sys
from PIL import Image

input_path = "assets/images/logo.png"
output_path = "assets/images/logo_padded.png"
bg_color = (255, 255, 255, 255) # white

try:
    img = Image.open(input_path).convert("RGBA")
    # Provide 30% padding
    new_size = int(max(img.width, img.height) * 1.5)
    padded = Image.new("RGBA", (new_size, new_size), bg_color)
    offset = ((new_size - img.width) // 2, (new_size - img.height) // 2)
    padded.paste(img, offset, img)
    padded.save(output_path, "PNG")
    print("Successfully padded logo.")
except Exception as e:
    print(f"Error padding image: {e}")
    sys.exit(1)

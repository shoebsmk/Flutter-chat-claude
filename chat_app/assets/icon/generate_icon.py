#!/usr/bin/env python3
"""
Generate app icon PNG from design specifications.
Creates a 1024x1024px icon with AI/chat hybrid design.
"""

try:
    from PIL import Image, ImageDraw
    import math
except ImportError:
    print("PIL (Pillow) is required. Install with: pip install Pillow")
    exit(1)

# Colors from app theme
INDIGO = (99, 102, 241)  # #6366F1
PURPLE = (139, 92, 246)  # #8B5CF6
LIGHT_INDIGO = (129, 140, 248)  # #818CF8
LIGHT_PURPLE = (167, 139, 250)  # #A78BFA
WHITE = (255, 255, 255)

def create_icon():
    size = 1024
    padding = 100  # Safe area padding
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Create gradient background
    for y in range(size):
        # Linear gradient from indigo to purple
        ratio = y / size
        r = int(INDIGO[0] * (1 - ratio) + PURPLE[0] * ratio)
        g = int(INDIGO[1] * (1 - ratio) + PURPLE[1] * ratio)
        b = int(INDIGO[2] * (1 - ratio) + PURPLE[2] * ratio)
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))
    
    # Draw rounded rectangle background
    corner_radius = 220
    draw.rounded_rectangle(
        [(0, 0), (size, size)],
        radius=corner_radius,
        fill=(INDIGO[0], INDIGO[1], INDIGO[2], 255)
    )
    
    # Overlay gradient effect
    for y in range(size):
        # Radial gradient effect (lighter at top)
        distance_from_top = y / size
        if distance_from_top < 0.5:
            factor = 1 - (distance_from_top * 0.3)
            r = min(255, int(INDIGO[0] * factor + LIGHT_INDIGO[0] * (1 - factor)))
            g = min(255, int(INDIGO[1] * factor + LIGHT_INDIGO[1] * (1 - factor)))
            b = min(255, int(INDIGO[2] * factor + LIGHT_INDIGO[2] * (1 - factor)))
            draw.line([(0, y), (size, y)], fill=(r, g, b, 200))
    
    # Center point
    center_x, center_y = size // 2, size // 2
    
    # Chat bubble dimensions
    bubble_width = 560
    bubble_height = 400
    bubble_x = center_x - bubble_width // 2
    bubble_y = center_y - bubble_height // 2
    bubble_radius = 80
    
    # Draw chat bubble body
    draw.rounded_rectangle(
        [(bubble_x, bubble_y), (bubble_x + bubble_width, bubble_y + bubble_height)],
        radius=bubble_radius,
        fill=(255, 255, 255, 242)  # White with slight transparency
    )
    
    # Draw chat bubble tail (pointing left)
    tail_points = [
        (bubble_x, center_y),
        (bubble_x - 60, center_y - 40),
        (bubble_x - 60, center_y + 40)
    ]
    draw.polygon(tail_points, fill=(255, 255, 255, 242))
    
    # AI circuit pattern on chat bubble
    pattern_opacity = 76  # 30% of 255
    
    # Horizontal lines
    line_y_positions = [center_y - 120, center_y, center_y + 120]
    for line_y in line_y_positions:
        draw.line(
            [(bubble_x + 40, line_y), (bubble_x + bubble_width - 40, line_y)],
            fill=(INDIGO[0], INDIGO[1], INDIGO[2], pattern_opacity),
            width=8
        )
    
    # Vertical lines
    line_x_positions = [center_x - 160, center_x, center_x + 160]
    for line_x in line_x_positions:
        draw.line(
            [(line_x, center_y - 120), (line_x, center_y + 120)],
            fill=(PURPLE[0], PURPLE[1], PURPLE[2], pattern_opacity),
            width=6
        )
    
    # AI nodes (circles at intersections)
    node_radius = 20
    for line_x in line_x_positions:
        for line_y in line_y_positions:
            # Draw circle
            draw.ellipse(
                [(line_x - node_radius, line_y - node_radius),
                 (line_x + node_radius, line_y + node_radius)],
                fill=(INDIGO[0] if line_y == center_y - 120 or line_y == center_y + 120 else PURPLE[0],
                      INDIGO[1] if line_y == center_y - 120 or line_y == center_y + 120 else PURPLE[1],
                      INDIGO[2] if line_y == center_y - 120 or line_y == center_y + 120 else PURPLE[2],
                      pattern_opacity)
            )
    
    # Sparkle dots around chat bubble
    sparkle_positions = [
        (bubble_x - 40, bubble_y - 40),
        (bubble_x + bubble_width + 40, bubble_y - 40),
        (bubble_x - 40, bubble_y + bubble_height + 40),
        (bubble_x + bubble_width + 40, bubble_y + bubble_height + 40)
    ]
    for pos in sparkle_positions:
        if 0 <= pos[0] < size and 0 <= pos[1] < size:
            draw.ellipse(
                [(pos[0] - 12, pos[1] - 12), (pos[0] + 12, pos[1] + 12)],
                fill=(LIGHT_INDIGO[0], LIGHT_INDIGO[1], LIGHT_INDIGO[2], 153)  # 60% opacity
            )
    
    # Decorative corner elements
    corner_radius_deco = 30
    corner_positions = [
        (200, 200),
        (size - 200, 200),
        (200, size - 200),
        (size - 200, size - 200)
    ]
    for pos in corner_positions:
        draw.ellipse(
            [(pos[0] - corner_radius_deco, pos[1] - corner_radius_deco),
             (pos[0] + corner_radius_deco, pos[1] + corner_radius_deco)],
            fill=(255, 255, 255, 102)  # 40% opacity white
        )
    
    return img

if __name__ == '__main__':
    print("Generating app icon...")
    icon = create_icon()
    output_path = 'app_icon.png'
    icon.save(output_path, 'PNG', optimize=True)
    print(f"Icon saved to {output_path}")


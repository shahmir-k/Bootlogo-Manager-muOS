#!/bin/bash

# Generate Test Images for Bootlogo Manager
# Creates test images in all supported formats with randomized colors

echo "Generating test images for Bootlogo Manager..."

# Create output directory
mkdir -p test_images

# Function to generate random color
random_color() {
    # Generate random RGB values
    local r=$((RANDOM % 256))
    local g=$((RANDOM % 256))
    local b=$((RANDOM % 256))
    echo "rgb($r,$g,$b)"
}

# Function to generate random pattern
generate_pattern() {
    local filename=$1
    local format=$2
    
    # Generate 4 random colors
    local color1=$(random_color)
    local color2=$(random_color)
    local color3=$(random_color)
    local color4=$(random_color)
    
    # Create a 2x2 pattern with random colors
    # Top row: color1 + color2
    # Bottom row: color3 + color4
    
    # Special handling for different formats
    case "$format" in
        *.ico|*.cur)
            # ICO/CUR files have size limits, use 256x256
            magick xc:"$color1" xc:"$color2" +append \( xc:"$color3" xc:"$color4" +append \) -append -resize 256x256 "test_images/$filename"
            ;;
        *.tiff|*.tif)
            # Create TIFF by first creating a PNG then converting
            magick xc:"$color1" xc:"$color2" +append \( xc:"$color3" xc:"$color4" +append \) -append -resize 600x600 "test_images/temp.png" && magick "test_images/temp.png" "test_images/$filename" && rm "test_images/temp.png"
            ;;
        *)
            # Standard approach for other formats
            magick xc:"$color1" xc:"$color2" +append \( xc:"$color3" xc:"$color4" +append \) -append -resize 600x600 "test_images/$filename"
            ;;
    esac
    
    echo "Generated: $filename"
}

# Supported formats from magick-wrapper.lua
formats=(
    "test.bmp"
    "test.png"
    "test.jpg"
    "test.jpeg"
    "test.gif"
    "test.tga"
    "test.webp"
    "test.ico"
    "test.cur"
    # Raw formats removed - require dimension specification
    # "test.rgb"
    # "test.rgba"
    # "test.bgr"
    # "test.bgra"
    # "test.gray"
    # "test.cmyk"
    "test.ppm"
    "test.pgm"
    "test.pbm"
    "test.pnm"
    "test.sgi"
    "test.sun"
    "test.ras"
    "test.pcx"
    "test.xpm"
    "test.psd"
    "test.tiff"
    "test.tif"
)

# Generate images for each format
for format in "${formats[@]}"; do
    generate_pattern "$format" "$format"
done

# Generate some additional PNG variants with different bit depths
echo "Generating PNG variants with different bit depths..."

# PNG8 (8-bit indexed)
magick xc:$(random_color) xc:$(random_color) +append \( xc:$(random_color) xc:$(random_color) +append \) -append -resize 600x600 -colors 256 "test_images/testPNG8.png"

# PNG24 (24-bit RGB)
magick xc:$(random_color) xc:$(random_color) +append \( xc:$(random_color) xc:$(random_color) +append \) -append -resize 600x600 -depth 8 "test_images/testPNG24.png"

# PNG32 (32-bit RGBA with transparency)
magick xc:$(random_color) xc:$(random_color) +append \( xc:$(random_color) xc:$(random_color) +append \) -append -resize 600x600 -alpha set -background transparent "test_images/testPNG32.png"

# PNG48 (48-bit RGB)
magick xc:$(random_color) xc:$(random_color) +append \( xc:$(random_color) xc:$(random_color) +append \) -append -resize 600x600 -depth 16 "test_images/testPNG48.png"

# PNG64 (64-bit RGBA)
magick xc:$(random_color) xc:$(random_color) +append \( xc:$(random_color) xc:$(random_color) +append \) -append -resize 600x600 -depth 16 -alpha set -background transparent "test_images/testPNG64.png"

echo "PNG variants generated:"
echo "  testPNG8.png (8-bit indexed)"
echo "  testPNG24.png (24-bit RGB)"
echo "  testPNG32.png (32-bit RGBA)"
echo "  testPNG48.png (48-bit RGB)"
echo "  testPNG64.png (64-bit RGBA)"

# Generate some special test cases
echo "Generating special test cases..."

# Test with transparency (GIF)
magick xc:$(random_color) xc:$(random_color) +append \( xc:$(random_color) xc:$(random_color) +append \) -append -resize 600x600 -alpha set -background transparent "test_images/test_transparent.gif"

# Test with animation (GIF)
magick -delay 100 xc:$(random_color) xc:$(random_color) +append \( xc:$(random_color) xc:$(random_color) +append \) -append -resize 600x600 -loop 0 "test_images/test_animated.gif"

# Test with different aspect ratios
magick xc:$(random_color) xc:$(random_color) +append \( xc:$(random_color) xc:$(random_color) +append \) -append -resize 800x400 "test_images/test_wide.bmp"
magick xc:$(random_color) xc:$(random_color) +append \( xc:$(random_color) xc:$(random_color) +append \) -append -resize 400x800 "test_images/test_tall.bmp"

# Test with gradients
magick -size 600x600 gradient:$(random_color)-$(random_color) "test_images/test_gradient.png"
magick -size 600x600 radial-gradient:$(random_color)-$(random_color) "test_images/test_radial.png"

echo "Special test cases generated:"
echo "  test_transparent.gif (with transparency)"
echo "  test_animated.gif (animated)"
echo "  test_wide.bmp (wide aspect ratio)"
echo "  test_tall.bmp (tall aspect ratio)"
echo "  test_gradient.png (linear gradient)"
echo "  test_radial.png (radial gradient)"

echo ""
echo "All test images generated in 'test_images/' directory!"
echo "Total files generated: $(( ${#formats[@]} + 5 + 6 ))"
echo ""
echo "You can now use these images to test the Bootlogo Manager's file browser preview feature."

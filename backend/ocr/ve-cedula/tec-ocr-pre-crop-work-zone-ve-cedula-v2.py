#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
import numpy
from PIL import Image, ImageDraw


SCRIPT_NAME = "tec-ocr-pre-crop-work-zone-ve-cedula.py"
BASE_IMAGE_WORK_ZONE_HEIGHT = 314
BASE_IMAGE_BLUE_STRIPE_HEIGHT = 14





# ---- Logging functions -------------------------------------------------------
def logInfo(msg):
    if not quiet_mode:
        print(f"[INFO]  {msg}", file=sys.stdout)
def logDebug(msg):
    if debug_mode:
        print(f"[DEBUG] {msg}", file=sys.stderr)
def logWarn(msg):
    print(f"[WARN]  {msg}", file=sys.stderr)
def logError(msg, exit=True, exit_code=1):
    print(f"[ERROR] {msg}", file=sys.stderr)
    print(f"")
    print(f"")
    if exit:
        sys.exit(exit_code)








# ---- Image processing functions ----------------------------------------------
def is_yellow_rgb(arr, r_min=150, g_min=150, b_max=120, diff_min=50):
    """
    Return a boolean mask where pixels are considered "yellow".
    Yellow: R and G high, B low, and R/G sufficiently higher than B
    """
    R = arr[..., 0].astype(numpy.int16)
    G = arr[..., 1].astype(numpy.int16)
    B = arr[..., 2].astype(numpy.int16)
    mask = (R >= r_min) & (G >= g_min) & (B <= b_max) & ((R - B) >= diff_min) & ((G - B) >= diff_min)
    logDebug(f"Yellow pixels detected: {numpy.sum(mask)}")
    return mask


def is_blue_rgb(arr, r_max=140, g_max=140, b_min=80, diff_min=20):
    """
    Return a boolean mask where pixels are considered "blue".
    Blue: B high, R/G low, B sufficiently higher than R/G
    """
    R = arr[..., 0].astype(numpy.int16)
    G = arr[..., 1].astype(numpy.int16)
    B = arr[..., 2].astype(numpy.int16)
    mask = (B >= b_min) & (R <= r_max) & (G <= g_max) & ((B - numpy.maximum(R, G)) >= diff_min)
    logDebug(f"Blue pixels detected: {numpy.sum(mask)}")
    return mask


def is_red_rgb(arr, r_min=120, g_max=100, b_max=100, diff_min=40):
    """
    Return a boolean mask where pixels are considered "red".
    Red: R high, G/B low, R sufficiently higher than G/B
    """
    R = arr[..., 0].astype(numpy.int16)
    G = arr[..., 1].astype(numpy.int16)
    B = arr[..., 2].astype(numpy.int16)
    mask = (R >= r_min) & (G <= g_max) & (B <= b_max) & ((R - numpy.maximum(G, B)) >= diff_min)
    logDebug(f"Red pixels detected: {numpy.sum(mask)}")
    return mask


def is_black_rgb(arr, r_max=10, g_max=10, b_max=10):
    """
    Return a boolean mask where pixels are considered "black".
    All channels are low
    """
    R = arr[..., 0].astype(numpy.int16)
    G = arr[..., 1].astype(numpy.int16)
    B = arr[..., 2].astype(numpy.int16)
    mask = (R <= r_max) & (G <= g_max) & (B <= b_max)
    logDebug(f"Black pixels detected: {numpy.sum(mask)}")
    return mask



# ---- Crop detection functions ----------------------------------------------
def find_vertical_crop(np_img, input_file, stripe_search_pct=0.25):
    """
    Find top (red) and bottom (based on blue stripe) vertical crop positions.
    Only considers the top `stripe_search_pct` of the image for stripe detection,
    and validates that blue stripes span most of the width to avoid false positives.
    - np_img: image as numpy array (H x W x 3)
    Returns (top, bottom, red_mask, blue_mask): vertical work zone crop limits and red/blue masks.
    """
    height, width, _ = np_img.shape
    stripes_search_region_height = int(height * stripe_search_pct)

    logDebug(f"Image dimensions: {width}x{height}, stripes search height: {stripes_search_region_height}")
    if stripes_search_region_height < 10:
        logError("Image height too small for stripe detection.", exit=True)
    # --- Debug outputs ---
    if debug_mode:
        base_name, base_ext = os.path.splitext(os.path.basename(input_file))
        base_ext = base_ext.lstrip('.')
        # Highlight search region on original image and save
        rbga_img = Image.fromarray(np_img).convert("RGBA")
        highlighted_rbga_img = Image.new("RGBA", rbga_img.size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(highlighted_rbga_img)
        draw.rectangle([0, 0, rbga_img.width, stripes_search_region_height], fill=(255,255,0,50))
        highlighted_stripes_search_region_img = Image.alpha_composite(rbga_img, highlighted_rbga_img)
        highlighted_stripes_search_region_img.save(os.path.join("tmp", f"{base_name}-stripes-search-region.png"))
        logDebug(f"Saved highlighted stripes search region to ./tmp/{base_name}-stripes-search-region.png")

    # --- Detect blue stripe only in stripes search region ---
    stripes_search_region = np_img[:stripes_search_region_height, :, :]
    blue_mask_region = is_blue_rgb(stripes_search_region)
    valid_rows = [r for r in range(blue_mask_region.shape[0]) if numpy.any(blue_mask_region[r, :])]
    if not valid_rows:
        logError("No valid blue stripe found. Unable to determine bottom crop limit.", exit=True)
    blue_stripe_top = valid_rows[0]
    blue_stripe_bottom = valid_rows[-1]
    blue_stripe_height = blue_stripe_bottom - blue_stripe_top + 1
    if blue_stripe_bottom < blue_stripe_top:
        logError("Blue stripe detection failed. Unable to determine bottom crop limit.", exit=True)
    logDebug(f"Blue stripe detected. Top: {blue_stripe_top}, bottom: {blue_stripe_bottom}, height: {blue_stripe_height}")

    # --- Detect top (red stripe start) in top region ---
    red_mask_region = is_red_rgb(stripes_search_region)
    red_rows = numpy.where(numpy.any(red_mask_region, axis=1))[0]
    if red_rows.size == 0:
        logError("No red stripe found. Unable to determine top crop limit.", exit=True)
    red_stripe_top = red_rows[0]
    red_stripe_bottom = red_rows[-1]
    if red_stripe_top >= blue_stripe_bottom:
        logWarn(f"Red stripe top ({red_stripe_top}) overlaps blue stripe bottom ({blue_stripe_bottom}). Adjusting...")
        red_stripe_top = blue_stripe_bottom + 1
        red_stripe_bottom = red_rows[-1]
    red_stripe_height = red_stripe_bottom - red_stripe_top + 1
    if red_stripe_bottom < red_stripe_top:
        logError("Red stripe detection failed after adjustment. Unable to determine top crop limit.", exit=True)
    logDebug(f"Red stripe detected. Top: {red_stripe_top}, bottom: {red_stripe_bottom}, height: {red_stripe_height}")

    # --- Extrapolate work zone height based on blue stripe ---
    scale_factor = blue_stripe_height / BASE_IMAGE_BLUE_STRIPE_HEIGHT
    work_zone_height = int(BASE_IMAGE_WORK_ZONE_HEIGHT * scale_factor)
    work_zone_top = red_stripe_top
    work_zone_bottom = min(work_zone_top + work_zone_height, height - 1)

    logDebug(f"Extrapolated work zone height: {work_zone_height}, vertical limits: Top={work_zone_top}, Bottom={work_zone_bottom}")

    # Create full-size masks for debug/output
    blue_mask_full = is_blue_rgb(np_img)
    red_mask_full = is_red_rgb(np_img)
    return work_zone_top, work_zone_bottom, red_mask_full, blue_mask_full


def find_horizontal_crop(np_img, input_file, red_mask, top, bottom):
    """
    Find left and right crop positions based on red pixels in cropped region.
    - np_img: image as numpy array (H x W x 3)
    - red_mask: boolean mask of red pixels
    - top, bottom: work zone vertical crop limits
    Returns (left, right): horizontal work zone crop limits
    """
    # Detect left and right red pixels based on red pixels in the cropped vertical region
    cropped_red = red_mask[top:bottom, :]
    cols = numpy.where(numpy.any(cropped_red, axis=0))[0]
    if cols.size == 0:
        logError(f"No red found during horizontal crop detection. Using full width.", exit=True)
    work_zone_left, work_zone_right = cols[0], cols[-1]
    return work_zone_left, work_zone_right








# ---- Main program ------------------------------------------------------------
def main():
    global quiet_mode, debug_mode
    # --- Args ---
    if len(sys.argv) < 3:
        logError("Usage: python {SCRIPT_NAME} <input_file> <output_file> [--quiet] [--debug]")
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    quiet_mode = ("--quiet" in sys.argv)
    debug_mode = ("--debug" in sys.argv)


    # --- Create tmp directory (if debug mode is defined) ---
    if debug_mode:
        os.makedirs("tmp", exist_ok=True)


    # --- Load image ---
    try:
        img = Image.open(input_file).convert("RGB")
    except Exception as e:
        logError(f"Unable to open image '{input_file}': {e}", exit=True)
    np_img = numpy.asarray(img)
    height, width, _ = np_img.shape
    logInfo(f"Image loaded: {input_file} ({width}x{height})")


    # --- Vertical crop detection ---
    logInfo(f"Detecting vertical crop limits (red top, extrapolated bottom via blue stripe)...")
    top, bottom, red_mask, blue_mask = find_vertical_crop(np_img, input_file)
    logInfo(f"  Top={top}, bottom={bottom}")


    # --- Horizontal crop detection ---
    logInfo(f"Detecting horizontal crop limits (based on red pixels)...")
    left, right = find_horizontal_crop(np_img, input_file, red_mask, top, bottom)
    logInfo(f"  Left={left}, right={right}")


    # --- Perform cropping ---
    cropped_work_zone = img.crop((left, top, right + 1, bottom + 1))


    # --- Debug outputs ---
    if debug_mode:
        base_name, base_ext = os.path.splitext(os.path.basename(input_file))
        base_ext = base_ext.lstrip('.')

        # Save highlighted work zone in original image
        highlighted_work_zone = img.convert("RGBA")
        overlay = Image.new("RGBA", highlighted_work_zone.size, (0, 0, 0, 0))  # transparent overlay
        draw_overlay = ImageDraw.Draw(overlay)
        draw_overlay.rectangle([left, top, right, bottom], fill=(255, 255, 0, 64))  # yellow 25% opaque
        highlighted_work_zone = Image.alpha_composite(highlighted_work_zone, overlay)
        highlighted_work_zone.save(os.path.join("tmp", f"{base_name}-highlighted-work-zone.{base_ext}"))

        # Save cropped work area
        cropped_work_zone.save(os.path.join("tmp", f"{base_name}-work-zone.{base_ext}"))

        # Save red/blue masks
        red_img = numpy.zeros((red_mask.shape[0], red_mask.shape[1], 3), dtype=numpy.uint8)
        red_img[..., 0] = red_mask * 255  # red channel
        Image.fromarray(red_img).save(os.path.join("tmp", f"{base_name}-mask-red.{base_ext}"))
        blue_img = numpy.zeros((blue_mask.shape[0], blue_mask.shape[1], 3), dtype=numpy.uint8)
        blue_img[..., 2] = blue_mask * 255  # blue channel
        Image.fromarray(blue_img).save(os.path.join("tmp", f"{base_name}-mask-blue.{base_ext}"))
        bluered_img = numpy.zeros((red_mask.shape[0], red_mask.shape[1], 3), dtype=numpy.uint8)
        bluered_img[..., 2] = blue_mask * 255  # blue channel
        bluered_img[..., 0] = red_mask * 255   # red channel
        Image.fromarray(bluered_img).save(os.path.join("tmp", f"{base_name}-mask-bluered.{base_ext}"))



        #Image.fromarray((red_mask * 255).astype(numpy.uint8)).save(os.path.join("tmp", f"mask_red_{base_name}"))
        #Image.fromarray((blue_mask * 255).astype(numpy.uint8)).save(os.path.join("tmp", f"mask_blue_{base_name}"))
        logDebug(f"Saved intermediate results to ./tmp")

    
    # --- Save output ---
    cropped_work_zone.save(output_file)
    logInfo(f"Cropped image saved to: {output_file}")








# ---- Entry point ---------------------------------------------------------------
if __name__ == "__main__":
    main()

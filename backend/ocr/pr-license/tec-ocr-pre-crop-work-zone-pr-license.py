#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
import numpy
import cv2
from PIL import Image, ImageDraw


SCRIPT_NAME = "tec-ocr-pre-crop-work-zone-pr-license.py"
BASE_IMAGE_DOCUMENT_WIDTH = 680
BASE_IMAGE_DOCUMENT_HEIGHT = 436
BASE_IMAGE_LEFT_GREEN_STRIPE_SEARCH_REGION_PCT = 0.40
BASE_IMAGE_LEFT_GREEN_STRIPE_LEFT = 178
BASE_IMAGE_LEFT_GREEN_STRIPE_TOP = 75
BASE_IMAGE_LEFT_GREEN_STRIPE_RIGHT = 204
BASE_IMAGE_LEFT_GREEN_STRIPE_BOTTOM = 405
BASE_IMAGE_LEFT_GREEN_STRIPE_WIDTH = BASE_IMAGE_LEFT_GREEN_STRIPE_RIGHT - BASE_IMAGE_LEFT_GREEN_STRIPE_LEFT
BASE_IMAGE_LEFT_GREEN_STRIPE_HEIGHT = BASE_IMAGE_LEFT_GREEN_STRIPE_BOTTOM - BASE_IMAGE_LEFT_GREEN_STRIPE_TOP
BASE_IMAGE_WORK_ZONE_LEFT = 204
BASE_IMAGE_WORK_ZONE_TOP = 75
BASE_IMAGE_WORK_ZONE_RIGHT = 530
BASE_IMAGE_WORK_ZONE_BOTTOM = 405
BASE_IMAGE_WORK_ZONE_WIDTH = BASE_IMAGE_WORK_ZONE_RIGHT - BASE_IMAGE_WORK_ZONE_LEFT
BASE_IMAGE_WORK_ZONE_HEIGHT = BASE_IMAGE_WORK_ZONE_BOTTOM - BASE_IMAGE_WORK_ZONE_TOP




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


def is_green_rgb(arr, r_max=120, g_min=100, b_max=120, diff_min=30):
    """
    Return a boolean mask where pixels are considered "green".
    Green: G alto, R/B bajos, G suficientemente mayor que R/B
    """
    R = arr[..., 0].astype(numpy.int16)
    G = arr[..., 1].astype(numpy.int16)
    B = arr[..., 2].astype(numpy.int16)
    mask = (G >= g_min) & (R <= r_max) & (B <= b_max) & ((G - numpy.maximum(R, B)) >= diff_min)
    logDebug(f"Green pixels detected: {numpy.sum(mask)}")
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



# ---- Crop detection functions ------------------------------------------------
def find_work_zone_coordinates(np_img, input_file, left_green_stripe_search_pct=BASE_IMAGE_LEFT_GREEN_STRIPE_SEARCH_REGION_PCT):
    """
    Detect the document work zone based exclusively on the left green (vertical) stripe position.
    The green stripe acts as a fixed reference anchor to extrapolate the full
    working area, independent of image offsets or bottom artifacts.

    Args:
        np_img: Numpy array (H x W x 3) with the RGB image.
        input_file: Original filename (used for debug outputs).
        left_green_stripe_search_pct: Fraction of image height to search for green stripe (left area).

    Returns:
        (left, top, right, bottom): work zone crop limits.
    """

    # --- Basic measurements ---------------------------------------------------
    height, width, _ = np_img.shape
    left_green_stripe_search_region_width = int(width * left_green_stripe_search_pct)
    if left_green_stripe_search_region_width < 50:
        logError("Image width too small for left green stripe detection.", exit=True)
    logDebug(f"Image dimensions: {width}x{height}, green stripe search width: {left_green_stripe_search_region_width}")

    if debug_mode:
        base_name, base_ext = os.path.splitext(os.path.basename(input_file))
        base_ext = base_ext.lstrip('.')
        green_mask = is_green_rgb(np_img)
        green_img = numpy.zeros((green_mask.shape[0], green_mask.shape[1], 3), dtype=numpy.uint8)
        green_img[..., 0] = 0
        green_img[..., 1] = green_mask * 255  # Green channel
        green_img[..., 2] = 0
        Image.fromarray(green_img).save(os.path.join("tmp", f"{base_name}-full-green-mask.png"))
        logDebug(f"Saved debug image with mask of green pixels to: {os.path.join('tmp', f'{base_name}-full-green-mask.png')}")
        rgba_img = Image.fromarray(np_img).convert("RGBA")
        overlay = Image.new("RGBA", rgba_img.size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay)
        draw.rectangle([0, 0, left_green_stripe_search_region_width, height], fill=(255, 255, 0, 60))
        Image.alpha_composite(rgba_img, overlay).save(os.path.join("tmp", f"{base_name}-left-green-stripe-search-region.png"))
        logDebug(f"Saved debug image with left green stripe search region to: {os.path.join('tmp', f'{base_name}-left-green-stripe-search-region.png')}")

    # --- Detect left green stripe ------------------------------------------------
    left_region = np_img[:, :left_green_stripe_search_region_width, :]
    green_mask_region = is_green_rgb(left_region)

    # --- Compute green pixel density per column to filter out noise ---------------
    col_density = numpy.sum(green_mask_region, axis=0) / green_mask_region.shape[0]
    density_threshold = 0.15  # Require at least 15% green pixels per column
    valid_cols = numpy.where(col_density > density_threshold)[0]
    if valid_cols.size == 0:
        logError("No valid green stripe columns found above density threshold.", exit=True)

    # --- Limit maximum width of green stripe to avoid dirt artifacts ---------
    expected_width = BASE_IMAGE_LEFT_GREEN_STRIPE_WIDTH
    max_width = int(expected_width * 2.0)  # allow up to 2x expected width
    left_green_stripe_left = valid_cols[0]
    left_green_stripe_right = min(valid_cols[0] + max_width, valid_cols[-1])

    # --- Detect top/bottom from cleaned mask --------------------------------
    cleaned_green_mask = green_mask_region[:, left_green_stripe_left:left_green_stripe_right]
    green_rows = numpy.where(numpy.any(cleaned_green_mask, axis=1))[0]
    if green_rows.size == 0:
        logError("No green rows found after noise filtering.", exit=True)
    left_green_stripe_top = green_rows[0]
    left_green_stripe_bottom = green_rows[-1]
    left_green_stripe_height = left_green_stripe_bottom - left_green_stripe_top
    logDebug(f"Left green stripe (filtered): l={left_green_stripe_left}, t={left_green_stripe_top}, r={left_green_stripe_right}, b={left_green_stripe_bottom}")

    # --- Extrapolate work zone based on green stripe position -----------------
    scale_factor = left_green_stripe_height / BASE_IMAGE_LEFT_GREEN_STRIPE_HEIGHT
    logDebug(f"Left green stripe height scale factor: {scale_factor:.4f} (instance image height {left_green_stripe_height} / base image height {BASE_IMAGE_LEFT_GREEN_STRIPE_HEIGHT})")

    work_zone_width = int(BASE_IMAGE_WORK_ZONE_WIDTH * scale_factor)
    work_zone_top = left_green_stripe_top
    work_zone_bottom = min(work_zone_top + int(BASE_IMAGE_WORK_ZONE_HEIGHT * scale_factor), height - 1)
    work_zone_left = left_green_stripe_right
    work_zone_right = min(work_zone_left + work_zone_width, width - 1)
    logDebug(f"Extrapolated work zone based on green stripe scale factor {scale_factor:.4f}: "
             f"L={work_zone_left}, T={work_zone_top}, R={work_zone_right}, B={work_zone_bottom}")

    if work_zone_right < work_zone_left or work_zone_bottom < work_zone_top:
        logError("Invalid work zone rectangle.", exit=True)

    if debug_mode:
        debug_img = Image.fromarray(np_img).convert("RGBA")
        draw = ImageDraw.Draw(debug_img)
        draw.rectangle([left_green_stripe_left, left_green_stripe_top, left_green_stripe_right, left_green_stripe_bottom], outline=(255, 0, 0, 255), width=2)
        draw.rectangle([work_zone_left, work_zone_top, work_zone_right, work_zone_bottom], outline=(0, 0, 255, 255), width=3)
        debug_img.save(os.path.join("tmp", f"{base_name}-left-green-stripe-and_work-zone-detection-hints.png"))
        logDebug("Saved debug image with left green stripe and work zone detection hints to: " + os.path.join("tmp", f"{base_name}-left-green-stripe-and_work-zone-detection-hints.png"))

    return work_zone_left, work_zone_top, work_zone_right, work_zone_bottom







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


    # --- Detect work zone crop limits ---
    logInfo(f"Detecting work zone limits via left green stripe (Puerto Rico license)...")
    left, top, right, bottom = find_work_zone_coordinates(np_img, input_file)
    logInfo(f"  Left={left}, top={top}, right={right}, bottom={bottom}")


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
        logDebug(f"Saved debug image with highlighted work zone to: " + os.path.join("tmp", f"{base_name}-highlighted-work-zone.{base_ext}"))

    
    # --- Save output ---
    cropped_work_zone.save(output_file)
    logInfo(f"Cropped image saved to: {output_file}")








# ---- Entry point ---------------------------------------------------------------
if __name__ == "__main__":
    main()

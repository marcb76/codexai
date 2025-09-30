#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
import numpy
import cv2
from PIL import Image, ImageDraw


SCRIPT_NAME = "tec-ocr-pre-crop-work-zone-ve-cedula.py"
BASE_IMAGE_DOCUMENT_WIDTH = 489
BASE_IMAGE_DOCUMENT_HEIGHT = 342
BASE_IMAGE_TOP_RED_STRIPE_SEARCH_REGION_PCT = 0.35
BASE_IMAGE_TOP_RED_STRIPE_LEFT = 53
BASE_IMAGE_TOP_RED_STRIPE_TOP = 51
BASE_IMAGE_TOP_RED_STRIPE_RIGHT = 498
BASE_IMAGE_TOP_RED_STRIPE_BOTTOM = 64
BASE_IMAGE_TOP_RED_STRIPE_WIDTH = BASE_IMAGE_TOP_RED_STRIPE_RIGHT - BASE_IMAGE_TOP_RED_STRIPE_LEFT
BASE_IMAGE_TOP_RED_STRIPE_HEIGHT = BASE_IMAGE_TOP_RED_STRIPE_BOTTOM - BASE_IMAGE_TOP_RED_STRIPE_TOP
BASE_IMAGE_WORK_ZONE_LEFT = 53
BASE_IMAGE_WORK_ZONE_TOP = 51
BASE_IMAGE_WORK_ZONE_RIGHT = 498
BASE_IMAGE_WORK_ZONE_BOTTOM = 347
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
def find_work_zone_coordinates(np_img, input_file, top_red_stripe_search_pct=BASE_IMAGE_TOP_RED_STRIPE_SEARCH_REGION_PCT):
    """
    Detect the document work zone based exclusively on the red stripe position.
    The red stripe acts as a fixed reference anchor to extrapolate the full
    working area, independent of image offsets or bottom artifacts.

    Args:
        np_img: Numpy array (H x W x 3) with the RGB image.
        input_file: Original filename (used for debug outputs).
        top_red_stripe_search_pct: Fraction of image height to search for red stripe (top area).

    Returns:
        (left, top, right, bottom): work zone crop limits.
    """

    # --- Basic measurements ---------------------------------------------------
    height, width, _ = np_img.shape
    top_red_stripe_search_region_height = int(height * top_red_stripe_search_pct)
    if top_red_stripe_search_region_height < 10:
        logError("Image height too small for top red stripe detection.", exit=True)
    logDebug(f"Image dimensions: {width}x{height}, red stripe search height: {top_red_stripe_search_region_height}")
    if debug_mode:
        # Save top red stripe search region on original image
        base_name, base_ext = os.path.splitext(os.path.basename(input_file))
        base_ext = base_ext.lstrip('.')
        rgba_img = Image.fromarray(np_img).convert("RGBA")
        overlay = Image.new("RGBA", rgba_img.size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay)
        draw.rectangle([0, 0, width, top_red_stripe_search_region_height], fill=(255, 255, 0, 60))
        Image.alpha_composite(rgba_img, overlay).save(os.path.join("tmp", f"{base_name}-top-red-stripe-search-region.png"))
        logDebug(f"Saved debug image with top red stripe search region to: {os.path.join('tmp', f'{base_name}-top-red-stripe-search-region.png')}")


    # --- Detect top red stripe ------------------------------------------------
    top_region = np_img[:top_red_stripe_search_region_height, :, :]
    red_mask_region = is_red_rgb(top_region)
    red_rows = numpy.where(numpy.any(red_mask_region, axis=1))[0]
    if red_rows.size == 0:
        logError("No top red stripe found (top/bottom). Unable to determine work zone limits.", exit=True)
    top_red_stripe_top = red_rows[0]
    top_red_stripe_bottom = red_rows[-1]
    red_cols = numpy.where(numpy.any(red_mask_region, axis=0))[0]
    if red_cols.size == 0:
        logError("No top red stripe found (left/right). Unable to determine work zone limits.", exit=True)
    top_red_stripe_left = red_cols[0]
    top_red_stripe_right = red_cols[-1]
    top_red_stripe_width = top_red_stripe_right - top_red_stripe_left
    logDebug(f"Top Red stripe detected: l={top_red_stripe_left}, t={top_red_stripe_top}, r={top_red_stripe_right}, b={top_red_stripe_bottom}")

    # --- Extrapolate work zone based on red stripe position ---
    scale_factor = top_red_stripe_width / BASE_IMAGE_TOP_RED_STRIPE_WIDTH
    logDebug(f"Top red stripe width scale factor: {scale_factor:.4f} (instance image width {top_red_stripe_width} / base image width {BASE_IMAGE_DOCUMENT_WIDTH})")
    # Extrapolate work zone height based on red stripe width scale factor
    work_zone_height = int(BASE_IMAGE_WORK_ZONE_HEIGHT * scale_factor)
    work_zone_left = top_red_stripe_left
    work_zone_right = top_red_stripe_right
    work_zone_top = top_red_stripe_bottom
    work_zone_bottom = top_red_stripe_bottom + work_zone_height
    logDebug(f"Extrapolated work zone based on red stripe scale factor {scale_factor:.4f}: "
             f"L={work_zone_left}, T={work_zone_top}, R={work_zone_right}, B={work_zone_bottom}")
    if work_zone_right < work_zone_left or work_zone_bottom < work_zone_top:
        logError("Invalid work zone rectangle.", exit=True)
    if debug_mode:
        # Save top red stripe and work zone detection hints
        debug_img = Image.fromarray(np_img).convert("RGBA")
        draw = ImageDraw.Draw(debug_img)
        draw.rectangle([top_red_stripe_left, top_red_stripe_top, top_red_stripe_right, top_red_stripe_bottom], outline=(255, 0, 0, 255), width=2)
        draw.rectangle([work_zone_left, work_zone_top, work_zone_right, work_zone_bottom], outline=(0, 0, 255, 255), width=3)
        debug_img.save(os.path.join("tmp", f"{base_name}-top-red-stripe-and_work-zone-detection-hints.png"))
        logDebug("Saved debug image with top red stripe and work zone detection hints to: " + os.path.join("tmp", f"{base_name}-top-red-stripe-and_work-zone-detection-hints.png"))
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
    logInfo(f"Detecting work zone limits (left, top, right, bottom, red) via top red stripe, bottom \"VENEZOLANO\" word and extrapolation...")
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

#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
import math
from PIL import Image, ImageDraw
import numpy as np

SCRIPT_NAME = "tec-ocr-pre-deskew-pr-license.py"
SLICE_HEIGHT = 8  # height in pixels for each horizontal slice




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
def is_green_rgb(arr, g_min=115, r_max=110, b_max=110, diff_min=50):
    """
    Return a boolean mask where pixels are considered "green" in RGB.
    Conditions:
      - G high, R/B low, and G sufficiently greater than max(R,B)
    """
    R = arr[..., 0].astype(np.int16)
    G = arr[..., 1].astype(np.int16)
    B = arr[..., 2].astype(np.int16)
    return (G >= g_min) & (R <= r_max) & (B <= b_max) & ((G - np.maximum(R, B)) >= diff_min)


SLICE_HEIGHT = 8  # height in pixels for each horizontal slice
def find_green_x_at_row(np_img, y, scan_zone_heights=(SLICE_HEIGHT, 12, 16, 20)):
    """
    Find the representative X for the green vertical stripe near a given row
    by scanning a narrow horizontal band around y. Returns median X of pixels detected as green.
    Only scans within the first 40% of image width (as per spec).
    """
    h, w, _ = np_img.shape
    x_max = int(round(0.40 * w))  # scan only the 40% of the image (from left to right)
    for hh in scan_zone_heights:
        y1 = max(0, y - hh)
        y2 = min(h, y + hh + 1)
        band = np_img[y1:y2, 0:x_max, :]
        green_mask = is_green_rgb(band)
        cols_with_green = np.any(green_mask, axis=0)
        xs = np.where(cols_with_green)[0]
        if xs.size > 0:
            return int(np.median(xs))
    return None


def rotate_pil(image, angle_deg):
    """
    Rotate the PIL image to deskew vertical green stripe.
    Positive angle from atan2 means slope downward to the right, so we rotate by -angle.
    """
    return image.rotate(-angle_deg, resample=Image.BICUBIC, expand=True)








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
        logError(f"Unable to open image '{input_file}': {e}")
    width, height = img.size
    logInfo(f"Image loaded: {input_file} ({width}x{height})")


    # Compute y positions at 40% and 70% height
    y_top = int(round(0.40 * height))
    y_bottom = int(round(0.70 * height))
    logInfo(f"Sampling horizontal bands at y={y_top} and y={y_bottom} (green stripe)")


    # Convert to numpy
    np_img = np.asarray(img)


    # Find X positions of green stripe in each row
    x_top = find_green_x_at_row(np_img, y_top)
    x_bottom = find_green_x_at_row(np_img, y_bottom)
    if debug_mode:
        # Save a marked image anyway to help debugging
        base_name, _ = os.path.splitext(os.path.basename(input_file))
        marked = img.copy()
        draw = ImageDraw.Draw(marked)
        draw.line([(0, y_top), (width, y_top)], fill="yellow", width=3)
        draw.line([(0, y_bottom), (width, y_bottom)], fill="yellow", width=3)
        marked_path = os.path.join("tmp", f"{base_name}-deskew-sampling.png")
        marked.save(marked_path)

    if x_top is None or x_bottom is None:
        logError("Could not detect the green stripe at one or both sampling rows.", False)
        if debug_mode:
            logDebug(f"Saved marked image (failed detection) to: {marked_path}")
        sys.exit(1)

    if debug_mode:
        logDebug(f"Saved marked image to: {marked_path}")
        logDebug(f"Green stripe detected at top row x={x_top}")
        logDebug(f"Green stripe detected at bottom row x={x_bottom}")


    # Compute angle (in degrees). In image coords, Y grows rightward.
    angle_deg = math.degrees(math.atan2(x_bottom - x_top, y_bottom - y_top))
    logInfo(f"Computed skew angle: {angle_deg:.3f} degrees")


    # Rotate image to deskew
    corrected = rotate_pil(img, angle_deg)


    # Save output
    corrected.save(output_file)
    logInfo(f"Deskewed image saved to: {output_file}")







# ---- Entry point -------------------------------------------------------------
if __name__ == "__main__":
    main()

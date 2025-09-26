#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
import math
from PIL import Image, ImageDraw
import numpy as np

SCRIPT_NAME = "tec-ocr-pre-deskew-ve-cedula.py"
SLICE_HALF_WIDTH = 4  # half-width in pixels for each vertical slice (total width ~ 2*HALF+1)




# ---- Logging functions -------------------------------------------------------
def logInfo(msg):
    if not quiet_mode:
        print(f"[INFO]  {msg}")
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
def is_red_rgb(arr, r_min=120, g_max=100, b_max=100, diff_min=40):
    """
    Return a boolean mask where pixels are considered "red" in RGB.
    Conditions:
      - R high, G/B low, and R sufficiently greater than max(G,B)
    """
    R = arr[..., 0].astype(np.int16)
    G = arr[..., 1].astype(np.int16)
    B = arr[..., 2].astype(np.int16)
    return (R >= r_min) & (G <= g_max) & (B <= b_max) & ((R - np.maximum(G, B)) >= diff_min)


def find_red_y_at_column(np_img, x, half_widths=(SLICE_HALF_WIDTH, 6, 10, 14)):
    """
    Find the representative Y for the red line near a given x by scanning
    a narrow vertical band around x. We return the median Y of rows that contain red.
    We progressively widen the band if nothing is found.
    """
    h, w, _ = np_img.shape
    for hw in half_widths:
        x1 = max(0, x - hw)
        x2 = min(w, x + hw + 1)  # slice end is exclusive
        band = np_img[:, x1:x2, :]                 # (h, band_w, 3)
        red_mask = is_red_rgb(band)                # (h, band_w)
        rows_with_red = np.any(red_mask, axis=1)   # (h,)
        ys = np.where(rows_with_red)[0]
        if ys.size > 0:
            # Use median for robustness against noise
            return int(np.median(ys))
    return None


def rotate_pil(image, angle_deg):
    """
    Rotate the PIL image by -angle_deg to deskew (make the red line horizontal).
    Positive angle from atan2 means line slopes downward to the right (image coords),
    so we rotate by -angle.
    """
    # PIL rotates counter-clockwise for positive angles.
    return image.rotate(angle_deg, resample=Image.BICUBIC, expand=True)








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


    # Compute x positions at 30% and 60% of width
    x_left = int(round(0.30 * width))
    x_right = int(round(0.60 * width))
    logInfo(f"Sampling vertical bands at X={x_left} and X={x_right}")


    # Convert to numpy for fast operations
    np_img = np.asarray(img)  # shape (H, W, 3) RGB


    # Find Y positions of the red line near each X
    y_left = find_red_y_at_column(np_img, x_left)
    y_right = find_red_y_at_column(np_img, x_right)
    if debug_mode:
        # Save a marked image anyway to help debugging
        base_name, base_ext = os.path.splitext(os.path.basename(input_file))
        marked = img.copy()
        draw = ImageDraw.Draw(marked)
        draw.line([(x_left, 0), (x_left, height)], fill="yellow", width=3)
        draw.line([(x_right, 0), (x_right, height)], fill="yellow", width=3)
        marked_path = os.path.join("tmp", f"{base_name}-deskew-sampling.png")
        marked.save(marked_path)

        # Save concatenated narrow slices around the two X positions
        hw = SLICE_HALF_WIDTH
        left_slice = img.crop((max(0, x_left - hw), 0, min(width, x_left + hw + 1), height))
        right_slice = img.crop((max(0, x_right - hw), 0, min(width, x_right + hw + 1), height))
        concat_w = left_slice.width + right_slice.width
        concat = Image.new("RGB", (concat_w, height))
        concat.paste(left_slice, (0, 0))
        concat.paste(right_slice, (left_slice.width, 0))
        sliced_path = os.path.join("tmp", f"{base_name}-deskew-sliced.png")
        concat.save(sliced_path)
    if y_left is None or y_right is None:
        logError("Could not detect the red header line at one or both sampling columns.", False)
        logDebug(f"Saved marked image (failed detection) to: {marked_path}")
        sys.exit(1)
    if debug_mode:
        logDebug(f"Saved marked image to: {marked_path}")
        logDebug(f"Saved concatenated slices to: {sliced_path}")
        if y_left is not None:
            logDebug(f"Detected line Y at X={x_left}:  {y_left}")
        if y_right is not None:
            logDebug(f"Detected line Y at X={x_right}: {y_right}")


    # Compute angle (in degrees). In image coords, Y grows downward.
    # angle = atan2(deltaY, deltaX). If positive -> line slopes downward to the right.
    angle_deg = math.degrees(math.atan2((y_right - y_left), (x_right - x_left)))
    logInfo(f"Computed skew angle: {angle_deg:.3f} degrees")


    # Rotate image to deskew
    corrected = rotate_pil(img, angle_deg)


    # Save output
    corrected.save(output_file)
    logInfo(f"Deskewed image saved to: {output_file}")







# ---- Entry point ---------------------------------------------------------------
if __name__ == "__main__":
    main()

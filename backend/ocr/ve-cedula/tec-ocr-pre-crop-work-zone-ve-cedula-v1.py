#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
import numpy as np
from PIL import Image


SCRIPT_NAME = "tec-ocr-pre-crop-work-zone-ve-cedula.py"





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
def is_yellow_rgb(arr, r_min=150, g_min=150, b_max=120):
    """
    Return a boolean mask where pixels are considered "yellow".
    """
    R = arr[..., 0].astype(np.int16)
    G = arr[..., 1].astype(np.int16)
    B = arr[..., 2].astype(np.int16)
    return (R >= r_min) & (G >= g_min) & (B <= b_max)


def is_blue_rgb(arr, b_min=120, r_max=100, g_max=100, diff_min=40):
    """
    Return a boolean mask where pixels are considered "blue".
    """
    R = arr[..., 0].astype(np.int16)
    G = arr[..., 1].astype(np.int16)
    B = arr[..., 2].astype(np.int16)
    return (B >= b_min) & (R <= r_max) & (G <= g_max) & ((B - np.maximum(R, G)) >= diff_min)


def is_red_rgb(arr, r_min=120, g_max=100, b_max=100, diff_min=40):
    """
    Return a boolean mask where pixels are considered "red".
    """
    R = arr[..., 0].astype(np.int16)
    G = arr[..., 1].astype(np.int16)
    B = arr[..., 2].astype(np.int16)
    return (R >= r_min) & (G <= g_max) & (B <= b_max) & ((R - np.maximum(G, B)) >= diff_min)


def is_black_rgb(arr, threshold=10):
    """
    Returns a boolean mask where pixels are considered "black".
    """
    R = arr[..., 0].astype(np.int16)
    G = arr[..., 1].astype(np.int16)
    B = arr[..., 2].astype(np.int16)
    return (R <= threshold) & (G <= threshold) & (B <= threshold)

# ---- Crop detection functions ----------------------------------------------
def find_vertical_crop(np_img):
    """
    Find top (red) and bottom (yellow) vertical crop positions.
    """
    red_mask = is_red_rgb(np_img)
    yellow_mask = is_yellow_rgb(np_img)

    red_rows = np.where(np.any(red_mask, axis=1))[0]
    yellow_rows = np.where(np.any(yellow_mask, axis=1))[0]

    top = red_rows[0] if red_rows.size > 0 else 0
    bottom = yellow_rows[-1] if yellow_rows.size > 0 else np_img.shape[0] - 1
    return top, bottom, red_mask, yellow_mask


def find_horizontal_crop(np_img, red_mask, top, bottom):
    """
    Find left and right crop positions based on red pixels in cropped region.
    """
    cropped_red = red_mask[top:bottom, :]

    cols = np.where(np.any(cropped_red, axis=0))[0]
    if cols.size > 0:
        left, right = cols[0], cols[-1]
    else:
        left, right = 0, np_img.shape[1] - 1
        logWarn(f"No red found during horizontal crop detection. Using full width.")
    return left, right








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
        sys.exit(1)
    np_img = np.asarray(img)
    height, width, _ = np_img.shape
    logInfo(f"Image loaded: {input_file} ({width}x{height})")


    # --- Vertical crop detection ---
    logInfo(f"Detecting vertical crop limits (red top, yellow bottom)...")
    top, bottom, red_mask, yellow_mask = find_vertical_crop(np_img)
    logInfo(f"Top={top}, Bottom={bottom}")


    # --- Horizontal crop detection ---
    logInfo(f"Detecting horizontal crop limits (based on red pixels)...")
    left, right = find_horizontal_crop(np_img, red_mask, top, bottom)
    logInfo(f"Left={left}, Right={right}")


    # --- Perform cropping ---
    cropped = img.crop((left, top, right + 1, bottom + 1))


    # --- Debug outputs ---
    if debug_mode:
        Image.fromarray((red_mask * 255).astype(np.uint8)).save(os.path.join("tmp", "mask_red.png"))
        Image.fromarray((yellow_mask * 255).astype(np.uint8)).save(os.path.join("tmp", "mask_yellow.png"))
        cropped.save(os.path.join("tmp", "cropped_debug.png"))
        logDebug(f"Saved intermediate results to ./tmp")


    # --- Save output ---
    cropped.save(output_file)
    logInfo(f"Cropped image saved to: {output_file}")







# ---- Entry point ---------------------------------------------------------------
if __name__ == "__main__":
    main()

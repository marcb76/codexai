#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
tec-ocr-pre-deskew-passport.py
--------------------------------
Deskews (straightens) passport images based on the MRZ area.
Requires: Pillow, numpy, opencv-python-headless
"""

import sys
import os
import math
import cv2
import numpy as np
from PIL import Image, ImageDraw


# ---- Global variables --------------------------------------------------------
SCRIPT_NAME = os.path.basename(__file__)



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
    if exit:
        sys.exit(exit_code)








# ---- Image processing functions ----------------------------------------------
def find_mrz_angle(input_file, np_img):
    """
    Detects the angle of the MRZ area using edge and line detection.
    Returns the angle in degrees (positive = tilt to the right).
    Automatically adjusts for vertical MRZs (rotated 90°).
    """
    gray = cv2.cvtColor(np_img, cv2.COLOR_RGB2GRAY)
    h, w = gray.shape
    logDebug(f"Gray image size: {w}x{h}")

    # Filter and binarization
    blur = cv2.GaussianBlur(gray, (5, 5), 0)
    _, thresh = cv2.threshold(blur, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    
    # Edges
    edges = cv2.Canny(thresh, 50, 150, apertureSize=3)
    if debug_mode:
        base_name, _ = os.path.splitext(os.path.basename(input_file))
        edges_path = os.path.join("tmp", f"{base_name}-deskew-edges.png")
        cv2.imwrite(edges_path, edges)
        logDebug(f"Saved edge-detected image to: {edges_path}")

    
    # Detect lines using Hough Transform
    lines = cv2.HoughLinesP(edges, 1, np.pi / 180, threshold=100, minLineLength=w * 0.4, maxLineGap=20)
    if lines is None:
        logError("No lines detected with Hough. Cannot calculate deskew.", exit=False)
        return 0.0


    # Convert to list of (x1,y1,x2,y2,angle,length)
    line_data = []
    for line in lines:
        x1, y1, x2, y2 = line[0]
        length = math.hypot(x2 - x1, y2 - y1)
        angle = math.degrees(math.atan2(y2 - y1, x2 - x1))
        line_data.append((x1, y1, x2, y2, angle, length))


    # Filter nearly horizontal lines (|angle| < 15°)
    horizontal = [l for l in line_data if abs(l[4]) < 15]
    if not horizontal:
        logWarn("No obvious horizontal lines detected, using all.")
        horizontal = line_data


    # Select longest line closest to bottom (typical MRZ position)
    horizontal.sort(key=lambda l: (-(l[5]), -(l[1] + l[3]) / 2))
    best_line = horizontal[0]
    x1, y1, x2, y2, angle, length = best_line
    logDebug(f"Selected MRZ line: ({x1},{y1})-({x2},{y2}) ang={angle:.3f} len={length:.1f}")
    corrected_angle = angle
    if abs(angle) > 75:  # MRZ is vertical
        center_x = (x1 + x2) / 2
        if center_x > w / 2:
            # MRZ on the right → rotate +90°
            corrected_angle = 90
            logDebug("MRZ detected on the RIGHT side → rotating -90°")
        else:
            # MRZ on the left → rotate -90°
            corrected_angle = -90
            logDebug("MRZ detected on the LEFT side → rotating +90°")
    if debug_mode:
        mrz_path = os.path.join("tmp", f"{base_name}-deskew-mrz-line.png")
        img_debug = Image.fromarray(np_img)
        draw = ImageDraw.Draw(img_debug)
        draw.line([(x1, y1), (x2, y2)], fill="red", width=4)
        margin_y = int(h * 0.05)
        top_y = max(0, min(y1, y2) - margin_y)
        bottom_y = min(h - 1, max(y1, y2) + margin_y)
        draw.rectangle([(0, top_y), (w - 1, bottom_y)], outline="yellow", width=3)
        img_debug.save(mrz_path)
        logDebug(f"Saved MRZ detected zone to: {mrz_path}")
    return corrected_angle


# ---- Image rotation function -------------------------------------------------
def rotate_image_pil(image, angle_deg):
    """
    Rotates the given PIL image by the specified angle.
    Positive angle means tilt to the right, so we rotate by -angle.
    """
    return image.rotate(-angle_deg, resample=Image.BICUBIC, expand=True)








# ---- Main program ------------------------------------------------------------
def main():
    global quiet_mode, debug_mode
    if len(sys.argv) < 3:
        logError(f"Usage: python {SCRIPT_NAME} <input_file> <output_file> [--quiet] [--debug]")
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    quiet_mode = ("--quiet" in sys.argv)
    debug_mode = ("--debug" in sys.argv)


    # --- Create tmp directory (if debug mode is defined) ---
    if debug_mode:
        os.makedirs("tmp", exist_ok=True)


    # Load image
    try:
        img = Image.open(input_file).convert("RGB")
    except Exception as e:
        logError(f"Unable to open image '{input_file}': {e}")
    np_img = np.array(img)
    h, w, _ = np_img.shape
    logInfo(f"Image loaded: {input_file} ({w}x{h})")


    # Detect MRZ angle
    angle_deg = find_mrz_angle(input_file, np_img)
    logInfo(f"Computed deskew angle: {angle_deg:.3f} degrees")

    
    # Rotate image to deskew
    corrected = rotate_image_pil(img, angle_deg)


    # Save output
    corrected.save(output_file)
    logInfo(f"Deskewed image saved to: {output_file}")








# ---- Entry point -------------------------------------------------------------
if __name__ == "__main__":
    main()

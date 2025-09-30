#!/bin/bash

# ------------------------------------------------------------------------------
# tec-ocr.sh
# Top level script to convert an image to structured data using OCR:
#   Crop predefined fields from an image (based on coordinates) and run Tesseract per field.
#   Field definitions and expected image metadata are read from an external .param file.
#
# Usage: ./tec-ocr.sh --image=path/to/image.png --layout=path/to/layout.param [--quiet] [--debug] [--help]
#   --image:  input image file (png, jpg, pdf [first page])
#   --layout: path to the layout .param file
#   --quiet:  minimal output
#   --debug:  debug output will be shown; intermediate files will be preserved.
#   --help:   Show this help message
#
# Requirements (at least):
#   - ImageMagick (use `convert` CLI)
#   - identify (from ImageMagick)
#   - tesseract OCR (+ language packs you use, e.g., tesseract-ocr-spa)
#   - jq (to build JSON output)
# Also requires the helper scripts and any additional commands defined in the layout .param file
#
#
#
#
# Sample .param layout file:
#    # Please note that lines starting with # are comments and will be ignored
#    # Output json file (if not specified, defaults to ve-cedula-TIMESTAMP.json)
#    # "TIMESTAMP" placeholder should be defined, if not it will be added (after filename and before file extension) automatically at runtime
#    OUTPUT=ve-cedula-TIMESTAMP.json
#    
#    # Image rectification and crop work zone specification
#    IMAGE_FORMAT_RECTIFICATION_SCRIPT=./ve-cedula/tec-ocr-pre-convert-to-png-ve-cedula.sh
#    IMAGE_DESKEW_RECTIFICATION_SCRIPT=./ve-cedula/tec-ocr-pre-deskew-ve-cedula.sh
#    IMAGE_CROP_WORK_ZONE_SCRIPT=./ve-cedula/tec-ocr-pre-crop-work-zone-ve-cedula.sh
#    BASE_IMAGE_WORK_ZONE_WIDTH=440
#    BASE_IMAGE_WORK_ZONE_HEIGHT=293
#    
#    # Enhance image command (optional but recommended, input and output file [INPUT and OUTPUT] will be replaced at runtime)
#    #IMAGE_ENHANCE_CMD=convert INPUT -colorspace Gray -contrast-stretch 0 -sharpen 0x1 OUTPUT                         # GOOD
#    #IMAGE_ENHANCE_CMD=convert INPUT -colorspace Gray -threshold 50% OUTPUT                                           # PRIME
#    IMAGE_ENHANCE_CMD=convert "INPUT" -colorspace Gray -auto-level -contrast-stretch 0 -sharpen 0x1 -density 300 "OUTPUT"
#    
#    
#    
#    
#    # Fields coordinates are based on image's reference work zone dimension. Actual fields coordinates will be extrapolated from image's actual work zone
#    # Fields (please define at least one. See how to specify each one in the following line)
#    # name|x|y|width|height|lang|psm|whitelist
#    nationality|151|25|22|21|spa|8|EV
#    number|172|25|110|21|spa|7|0123456789
#    
#    lastName|32|47|220|21|spa|7|
#    firstName|32|72|220|21|spa|7|
#    
#    birthDate|97|154|93|20|spa|8|0123456789/
#    civilState|188|154|102|20|spa|8|CASDOLTERIVU
#    issueDate|98|214|91|19|spa|8|0123456789/
#    expiryDate|190|214|89|19|spa|8|0123456789/
# ------------------------------------------------------------------------------
set -euo pipefail








# ---- Helper: print usage and exit --------------------------------------------
usage() {
  local message="$1"
  if [ "$message" != "" ]; then
      echo "[ERROR] $message" >&2
  fi
  logInfo "  Usage: $0 --image=path/to/image.png --layout=path/to/layout.param [--quiet] [--debug] [--help]"
  logInfo "         --image:  input image file (png, jpg, pdf [first page])"
  logInfo "         --layout: path to the layout .param file"
  logInfo "         --quiet:  minimal output"
  logInfo "         --debug:  debug output will be shown; intermediate files will be preserved."
  logInfo "         --help:   Show this help message"
    [[ -z "$QUIET_MODE" ]] && echo
    [[ -z "$QUIET_MODE" ]] && echo
    [[ -z "$message" ]] && exit 0
    exit 1
}

# ---- Helper: check if command exists -----------------------------------------
need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    logError "'$1' is not installed or not in PATH."
  fi
}

# ---- Helper: logging functions -----------------------------------------------
logInfo() {
  if [[ -z "$QUIET_MODE" ]]; then
    echo "[INFO]  $1"
  fi
}
logDebug() {
  if [[ -n "$DEBUG_MODE" ]]; then
    echo "[DEBUG] $1" >&2
  fi
}
logWarn() {
  echo "[WARN]  $1" >&2
}
logError() {
  echo "[ERROR] $1" >&2
  echo >&2
  echo >&2
  exit 1
}

# ---- Helper: get param from layout file --------------------------------------
get_param_kv() {
  # prints value of KEY= from LAYOUT_FILE, empty if not present
  local key="$1"
  awk -F= -v k="$key" '
    $1==k {
      sub(/#.*/, "", $2)
      sub(/^[ \t]+/, "", $2)
      sub(/[ \t]+$/, "", $2)
      print $2
      exit
    }
  ' "$LAYOUT_FILE"
}

# ---- Helper: run OCR for a single field --------------------------------------
# Arguments: name x y w h lang psm whitelist
ocr_field() {
  local name="$1" x="$2" y="$3" w="$4" h="$5" lang="$6" psm="$7" whitelist="${8:-}"
  local crop_img="$TMP_DIR/${TMP_IMAGE_FILE_NAME}-temp-${TMP_IMAGE_FILE_TIMESTAMP}-${name}.png"
  local out_base="$TMP_DIR/${TMP_IMAGE_FILE_NAME}-temp-${TMP_IMAGE_FILE_TIMESTAMP}-${name}"

  # Crop the region of interest (ROI)
  # +repage ensures geometry is reset after cropping
  logDebug "         convert $IMAGE_FILE -crop \"${w}x${h}+${x}+${y}\" +repage $crop_img"
  convert "$IMAGE_FILE" -crop "${w}x${h}+${x}+${y}" +repage "$crop_img"

  # Build Tesseract command
  # --oem 1 uses LSTM engine; psm defaults to 6 if not provided
  local psm_val="${psm:-6}"
  if [[ -n "$whitelist" ]]; then
    logDebug "         tesseract $crop_img $out_base -l ${lang:-eng} --oem 1 --psm $psm_val -c tessedit_char_whitelist=$whitelist"
    tesseract "$crop_img" "$out_base" -l "${lang:-eng}" --oem 1 --psm "$psm_val" -c "tessedit_char_whitelist=$whitelist" >/dev/null 2>&1
  else
    logDebug "         tesseract $crop_img $out_base -l ${lang:-eng} --oem 1 --psm $psm_val"
    tesseract "$crop_img" "$out_base" -l "${lang:-eng}" --oem 1 --psm "$psm_val" >/dev/null 2>&1
  fi

  # Read output, remove CRs/newlines, trim leading/trailing spaces
  # (do NOT collapse internal spaces)
  if [[ -f "$out_base.txt" ]]; then
    sed 's/\r//g' "$out_base.txt" | tr -d '\n' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g'
  else
    echo ""
  fi
}

# ---- Helper: cleanup temporary files -----------------------------------------
cleanup() {
  rm -rf "$TMP_DIR";
}








## Entry point
# ---- Parse arguments and initialize variables --------------------------------
QUIET_MODE=""
DEBUG_MODE=""
for arg in "$@"; do
  case "$arg" in
    --quiet)    QUIET_MODE="1";;
  esac
done
if [[ -z "$QUIET_MODE" ]]; then
  clear
fi
logInfo ""
logInfo ""
logInfo ""
logInfo "-----------------------------------------------------------"
logInfo "-- tec-ocr.sh - Image OCR Scanner"
logInfo "-- Experimental"
logInfo "-- "
logInfo "-- "
logInfo "-- Marc Bonet"
logInfo "-- The Eniac Corporation"
logInfo "-- Copyright TEC - Ago.2025"
logInfo "-----------------------------------------------------------"
logInfo ""
logInfo ""
logInfo ""
logInfo ""
logInfo ""
logInfo ""




# ---- Parse arguments ---------------------------------------------------------
logInfo "Parsing arguments..."
IMAGE_FILE=""
LAYOUT_FILE=""
DEBUG_FLAG=""
for arg in "$@"; do
  case "$arg" in
    --image=*)  IMAGE_FILE="${arg#*=}";;
    --layout=*) LAYOUT_FILE="${arg#*=}";;
    --quiet)    QUIET_MODE="1";;
    --debug)    DEBUG_MODE="1";;
    --help)     usage "";;
    *)          usage "Invalid arguments: Unknown argument $arg";;
  esac
done
[[ -z "$IMAGE_FILE" ]] && usage "Invalid arguments: --image is required."
[[ -z "$LAYOUT_FILE" ]] && usage "Invalid arguments: --layout is required."
[[ ! -z "$DEBUG_MODE" ]] && DEBUG_FLAG="--debug"
IMAGE_FORMAT_RECTIFICATION_SCRIPT=""
IMAGE_DESKEW_RECTIFICATION_SCRIPT=""
IMAGE_CROP_WORK_ZONE_SCRIPT=""
IMAGE_ENHANCE_CMD=""
BASE_IMAGE_WORK_ZONE_WIDTH=""
BASE_IMAGE_WORK_ZONE_HEIGHT=""
IMAGE_WORK_ZONE_WIDTH=""
IMAGE_WORK_ZONE_HEIGHT=""
IMAGE_X_EXTRAPOLATION_FACTOR=""
IMAGE_Y_EXTRAPOLATION_FACTOR=""




# ---- Temp workspace & cleanup ------------------------------------------------
TMP_DIR="$PWD/tmp"
logInfo "Initializing temporary workspace..."
#cleanup
if [[ -z "$DEBUG_MODE" ]]; then
  trap cleanup EXIT
fi
if [[ ! -d "$TMP_DIR" ]]; then
  mkdir "$TMP_DIR"
fi
TMP_IMAGE_FILE="$(basename "$IMAGE_FILE")"      # → MarcB-Cedula.png
TMP_IMAGE_FILE_NAME="${TMP_IMAGE_FILE%.*}"          # → MarcB-Cedula
TMP_IMAGE_FILE_EXT="${TMP_IMAGE_FILE##*.}"                # → png
TMP_IMAGE_FILE_TIMESTAMP=$(date +"%d%m%Y%H%M%S%3N")
TMP_IMAGE_FILE="$TMP_DIR/${TMP_IMAGE_FILE_NAME}-temp-${TMP_IMAGE_FILE_TIMESTAMP}.${TMP_IMAGE_FILE_EXT}"




# ---- Check dependencies ------------------------------------------------------
logInfo "Checking dependencies..."
need_cmd convert
need_cmd identify
need_cmd tesseract
need_cmd jq
need_cmd awk
need_cmd sed
need_cmd tr
need_cmd rm
need_cmd mkdir
need_cmd basename
need_cmd dirname
need_cmd mktemp
need_cmd pwd
need_cmd trap
need_cmd eval




# ---- Validate input files ----------------------------------------------------
logInfo "Validating input files..."
if [[ ! -f "$IMAGE_FILE" ]]; then
  logError "Error: image '$IMAGE_FILE' not found." >&2
fi
if [[ ! -f "$LAYOUT_FILE" ]]; then
  logError "Error: layout file '$LAYOUT_FILE' not found." >&2
fi




# ---- Read expected metadata from .param (optional but recommended) -----------
logInfo "Reading image metadata and layout information from $LAYOUT_FILE..."
# Lines like: 
#   OUTPUT=ve-cedula-TIMESTAMP.json
#   IMAGE_FORMAT_RECTIFICATION_SCRIPT=./tec-ocr-pre-convert-to-png-ve-cedula.sh
#   IMAGE_DESKEW_RECTIFICATION_SCRIPT=./tec-ocr-pre-deskew-ve-cedula.sh
#   IMAGE_CROP_WORK_ZONE_SCRIPT=/.tec-ocr-pre-crop-work-zone-ve-cedula.sh
#   BASE_IMAGE_WORK_ZONE_WIDTH=686
#   BASE_IMAGE_WORK_ZONE_HEIGHT=505
#   IMAGE_ENHANCE_CMD=convert INPUT -colorspace Gray -threshold 50% OUTPUT
OUTPUT_FILE="$(get_param_kv OUTPUT || true)"
OUTPUT_FILE=$(echo "$OUTPUT_FILE" | tr -d '\r')
if [[ -z "$OUTPUT_FILE" ]]; then
    logWarn "WARNING: OUTPUT not defined in param file. Using default 've-cedula-TIMESTAMP.json'."
    OUTPUT_FILE="ve-cedula-TIMESTAMP.json"
fi
if [[ "$OUTPUT_FILE" != *"TIMESTAMP"* ]]; then
    logWarn "WARNING: OUTPUT does not contain TIMESTAMP placeholder. Adding it automatically."
    OUTPUT_FILE_NAME="${OUTPUT_FILE%.*}"
    OUTPUT_FILE_EXT="${OUTPUT_FILE##*.}"
    OUTPUT_FILE="${OUTPUT_FILE_NAME}-TIMESTAMP.${OUTPUT_FILE_EXT}"
fi
OUTPUT_FILE="${OUTPUT_FILE//TIMESTAMP/$TMP_IMAGE_FILE_TIMESTAMP}"
IMAGE_FORMAT_RECTIFICATION_SCRIPT="$(get_param_kv IMAGE_FORMAT_RECTIFICATION_SCRIPT || true)"
IMAGE_FORMAT_RECTIFICATION_SCRIPT=$(echo "$IMAGE_FORMAT_RECTIFICATION_SCRIPT" | tr -d '\r')
IMAGE_DESKEW_RECTIFICATION_SCRIPT="$(get_param_kv IMAGE_DESKEW_RECTIFICATION_SCRIPT || true)"
IMAGE_DESKEW_RECTIFICATION_SCRIPT=$(echo "$IMAGE_DESKEW_RECTIFICATION_SCRIPT" | tr -d '\r')
IMAGE_CROP_WORK_ZONE_SCRIPT="$(get_param_kv IMAGE_CROP_WORK_ZONE_SCRIPT || true)"
IMAGE_CROP_WORK_ZONE_SCRIPT=$(echo "$IMAGE_CROP_WORK_ZONE_SCRIPT" | tr -d '\r')
BASE_IMAGE_WORK_ZONE_WIDTH="$(get_param_kv BASE_IMAGE_WORK_ZONE_WIDTH || true)"
BASE_IMAGE_WORK_ZONE_WIDTH=$(echo "$BASE_IMAGE_WORK_ZONE_WIDTH" | tr -cd '0-9')
BASE_IMAGE_WORK_ZONE_HEIGHT="$(get_param_kv BASE_IMAGE_WORK_ZONE_HEIGHT || true)"
BASE_IMAGE_WORK_ZONE_HEIGHT=$(echo "$BASE_IMAGE_WORK_ZONE_HEIGHT" | tr -cd '0-9')
IMAGE_ENHANCE_CMD="$(get_param_kv IMAGE_ENHANCE_CMD || true)"
IMAGE_ENHANCE_CMD=$(echo "$IMAGE_ENHANCE_CMD" | tr -d '\r')
logInfo "Validating metadata and layout information..."
if [[ -n "$IMAGE_FORMAT_RECTIFICATION_SCRIPT" ]]; then
  need_cmd "$IMAGE_FORMAT_RECTIFICATION_SCRIPT"
fi
if [[ -n "$IMAGE_DESKEW_RECTIFICATION_SCRIPT" ]]; then
  need_cmd "$IMAGE_DESKEW_RECTIFICATION_SCRIPT"
fi
if [[ -n "$IMAGE_CROP_WORK_ZONE_SCRIPT" ]]; then
  need_cmd "$IMAGE_CROP_WORK_ZONE_SCRIPT"
fi
if [[ -z "$BASE_IMAGE_WORK_ZONE_WIDTH" ]]; then
  logError "BASE_IMAGE_WORK_ZONE_WIDTH not defined in param file."
fi
if [[ -z "$BASE_IMAGE_WORK_ZONE_HEIGHT" ]]; then
  logError "BASE_IMAGE_WORK_ZONE_HEIGHT not defined in param file."
fi
if [[ -n "$IMAGE_ENHANCE_CMD" ]]; then
  if [[ "$IMAGE_ENHANCE_CMD" != *"INPUT"* || "$IMAGE_ENHANCE_CMD" != *"OUTPUT"* ]]; then
    logError "IMAGE_ENHANCE_CMD must contain INPUT and OUTPUT placeholders."
  fi
  IMAGE_ENHANCE_CMD_COMMAND="${IMAGE_ENHANCE_CMD%% *}"
  need_cmd "$IMAGE_ENHANCE_CMD_COMMAND"
fi
logInfo "  Parameters:"
logInfo "    Image file:            $IMAGE_FILE"
logInfo "    Layout file:           $LAYOUT_FILE"
logInfo "    Output file:           $OUTPUT_FILE"
[[ -n "$QUIET_MODE" ]] && logInfo "    Quiet mode:            enabled" || logInfo "    Quiet mode:            disabled"
logInfo "    Debug mode:            ${DEBUG_MODE:+enabled}"
if [[ -n "$DEBUG_MODE" ]]; then
  logInfo "                           Temporary workspace $TMP_DIR will not be deleted after script exits."
fi
logInfo "    Convert to png script: $IMAGE_FORMAT_RECTIFICATION_SCRIPT"
if [[ -z "$IMAGE_FORMAT_RECTIFICATION_SCRIPT" ]]; then
  logWarn "      WARNING: IMAGE_FORMAT_RECTIFICATION_SCRIPT not defined in param file. Using default convert to png script."
  IMAGE_FILE_EXT="${IMAGE_FILE##*.}"
  if [[ "$IMAGE_FILE_EXT" != "png" ]]; then
    logError "IMAGE_FORMAT_RECTIFICATION_SCRIPT not defined and input image is not png. Please define IMAGE_FORMAT_RECTIFICATION_SCRIPT in param file."
  fi
fi
logInfo "    Deskew script:         $IMAGE_DESKEW_RECTIFICATION_SCRIPT"
if [[ -z "$IMAGE_DESKEW_RECTIFICATION_SCRIPT" ]]; then
  logWarn "      WARNING: IMAGE_DESKEW_RECTIFICATION_SCRIPT not defined in param file. No deskewing will be applied."
fi
logInfo "    Crop work zone script: $IMAGE_CROP_WORK_ZONE_SCRIPT"
if [[ -z "$IMAGE_CROP_WORK_ZONE_SCRIPT" ]]; then
  logWarn "      WARNING: IMAGE_CROP_WORK_ZONE_SCRIPT not defined in param file. No cropping will be applied."
fi
logInfo "    Base work zone width:  $BASE_IMAGE_WORK_ZONE_WIDTH"
logInfo "    Base work zone height: $BASE_IMAGE_WORK_ZONE_HEIGHT"
logInfo "    Enhance image command:  $IMAGE_ENHANCE_CMD"
if [[ -z "$IMAGE_ENHANCE_CMD" ]]; then
  logWarn "      WARNING: IMAGE_ENHANCE_CMD not defined in param file. No enhancement will be applied."
fi
if [[ -n "$IMAGE_FORMAT_RECTIFICATION_SCRIPT" ]]; then
  need_cmd "$IMAGE_FORMAT_RECTIFICATION_SCRIPT"
fi
if [[ -n "$IMAGE_DESKEW_RECTIFICATION_SCRIPT" ]]; then
  need_cmd "$IMAGE_DESKEW_RECTIFICATION_SCRIPT"
fi
if [[ -n "$IMAGE_CROP_WORK_ZONE_SCRIPT" ]]; then
  need_cmd "$IMAGE_CROP_WORK_ZONE_SCRIPT"
fi
if [[ -n "$IMAGE_ENHANCE_CMD" ]]; then
  need_cmd "$IMAGE_ENHANCE_CMD_COMMAND"
fi




# ---- Convert input image to png if needed ------------------------------------
if [[ -n "$IMAGE_FORMAT_RECTIFICATION_SCRIPT" ]]; then
  logInfo ""
  logInfo ""
  logInfo "Converting input image to PNG format..."
  CONVERTED_IMAGE_FILE_NAME="${TMP_IMAGE_FILE%.*}"
  CONVERTED_IMAGE_FILE_EXT="${TMP_IMAGE_FILE##*.}"
  CONVERTED_IMAGE_FILE="${CONVERTED_IMAGE_FILE_NAME}-converted.png"
  logDebug "  $IMAGE_FORMAT_RECTIFICATION_SCRIPT --input_file=\"$IMAGE_FILE\" --output_file=\"$CONVERTED_IMAGE_FILE\" --quiet $DEBUG_FLAG"
  IMAGE_FILE="$($IMAGE_FORMAT_RECTIFICATION_SCRIPT --input_file="$IMAGE_FILE" --output_file="$CONVERTED_IMAGE_FILE" --quiet $DEBUG_FLAG)"
  IMAGE_FILE_NAME="$(basename "$IMAGE_FILE")"
  IMAGE_FILE_EXT="${IMAGE_FILE##*.}"
  logInfo "PNG format image: $IMAGE_FILE"
fi




# ---- Apply image deskew script, if defined -----------------------------------
if [[ -n "$IMAGE_DESKEW_RECTIFICATION_SCRIPT" ]]; then
  logInfo ""
  logInfo ""
  logInfo "Deskewing image..."
  DESKEWED_IMAGE_FILE_NAME="${IMAGE_FILE%.*}"
  DESKEWED_IMAGE_FILE_EXT="${IMAGE_FILE##*.}"
  DESKEWED_IMAGE_FILE="${DESKEWED_IMAGE_FILE_NAME}-deskewed.${DESKEWED_IMAGE_FILE_EXT}"
  logDebug "  $IMAGE_DESKEW_RECTIFICATION_SCRIPT --input_file=\"$IMAGE_FILE\" --output_file=\"$DESKEWED_IMAGE_FILE\" --quiet $DEBUG_FLAG"
  IMAGE_FILE="$($IMAGE_DESKEW_RECTIFICATION_SCRIPT --input_file="$IMAGE_FILE" --output_file="$DESKEWED_IMAGE_FILE" --quiet $DEBUG_FLAG)"
  IMAGE_FILE_NAME="$(basename "$IMAGE_FILE")"
  IMAGE_FILE_EXT="${IMAGE_FILE##*.}"
  logInfo "Deskewed image: $IMAGE_FILE"
fi




# ---- Apply image crop work zone script, if defined ---------------------------
if [[ -n "$IMAGE_CROP_WORK_ZONE_SCRIPT" ]]; then
  logInfo ""
  logInfo ""
  logInfo "Cropping work zone..."
  CROPPED_WORK_ZONE_IMAGE_FILE_NAME="${IMAGE_FILE%.*}"
  CROPPED_WORK_ZONE_IMAGE_FILE_EXT="${IMAGE_FILE##*.}"
  CROPPED_WORK_ZONE_IMAGE_FILE="${CROPPED_WORK_ZONE_IMAGE_FILE_NAME}-cropped.${CROPPED_WORK_ZONE_IMAGE_FILE_EXT}"
  logDebug "  $IMAGE_CROP_WORK_ZONE_SCRIPT --input_file=\"$IMAGE_FILE\" --output_file=\"$CROPPED_WORK_ZONE_IMAGE_FILE\" --quiet $DEBUG_FLAG"
  IMAGE_FILE="$($IMAGE_CROP_WORK_ZONE_SCRIPT --input_file="$IMAGE_FILE" --output_file="$CROPPED_WORK_ZONE_IMAGE_FILE" --quiet $DEBUG_FLAG)"
  IMAGE_FILE_NAME="$(basename "$IMAGE_FILE")"
  IMAGE_FILE_EXT="${IMAGE_FILE##*.}"
  logInfo "Cropped work zone image: $IMAGE_FILE"
fi




# ---- Validate actual image metadata and compute extrapolation factors --------
logInfo ""
logInfo ""
logInfo "Validating actual image metadata..."
read IMAGE_WORK_ZONE_WIDTH IMAGE_WORK_ZONE_HEIGHT < <(identify -format "%w %h\n" "$IMAGE_FILE")
IMAGE_WORK_ZONE_WIDTH=$(echo "$IMAGE_WORK_ZONE_WIDTH" | tr -cd '0-9')
IMAGE_WORK_ZONE_HEIGHT=$(echo "$IMAGE_WORK_ZONE_HEIGHT" | tr -cd '0-9')
if [[ "$IMAGE_WORK_ZONE_WIDTH" -le 0 || "$IMAGE_WORK_ZONE_HEIGHT" -le 0 ]]; then
  logError "Could not determine actual image dimensions."
fi
logDebug "  Actual image work zone dimensions:"
logDebug "    Width:  ${IMAGE_WORK_ZONE_WIDTH}"
logDebug "    Height: ${IMAGE_WORK_ZONE_HEIGHT}"
logDebug "  Base image work zone dimensions:"
logDebug "    Width:  ${BASE_IMAGE_WORK_ZONE_WIDTH}"
logDebug "    Height: ${BASE_IMAGE_WORK_ZONE_HEIGHT}"
logInfo "Calculating extrapolation factors for actual image work zone..."
if [[ "$IMAGE_WORK_ZONE_WIDTH" -lt "$BASE_IMAGE_WORK_ZONE_WIDTH" ]]; then
  logWarn "  WARNING: Actual image width ($IMAGE_WORK_ZONE_WIDTH) is less than base work zone width ($BASE_IMAGE_WORK_ZONE_WIDTH)."
fi
if [[ "$IMAGE_WORK_ZONE_HEIGHT" -lt "$BASE_IMAGE_WORK_ZONE_HEIGHT" ]]; then
  logWarn "  WARNING: Actual image height ($IMAGE_WORK_ZONE_HEIGHT) is less than base work zone height ($BASE_IMAGE_WORK_ZONE_HEIGHT)."
fi
# Compute extrapolation factors
IMAGE_X_EXTRAPOLATION_FACTOR=$(awk "BEGIN {printf \"%.6f\", $IMAGE_WORK_ZONE_WIDTH / $BASE_IMAGE_WORK_ZONE_WIDTH}")
IMAGE_Y_EXTRAPOLATION_FACTOR=$(awk "BEGIN {printf \"%.6f\", $IMAGE_WORK_ZONE_HEIGHT / $BASE_IMAGE_WORK_ZONE_HEIGHT}")
logDebug "  Extrapolation factors:"
logDebug "    Width factor:  $IMAGE_X_EXTRAPOLATION_FACTOR"
logDebug "    Height factor: $IMAGE_Y_EXTRAPOLATION_FACTOR"




# --- Apply image enhance command, if defined ----------------------------------
if [[ -n "$IMAGE_ENHANCE_CMD" ]]; then
  logInfo ""
  logInfo ""
  logInfo "Enhancing image quality..."
  ENHANCED_IMAGE_FILE_NAME="${IMAGE_FILE%.*}"
  ENHANCED_IMAGE_FILE_EXT="${IMAGE_FILE##*.}"
  ENHANCED_IMAGE_FILE="${ENHANCED_IMAGE_FILE_NAME}-enhanced.${ENHANCED_IMAGE_FILE_EXT}"
  cmd="${IMAGE_ENHANCE_CMD//INPUT/$IMAGE_FILE}"
  cmd="${cmd//OUTPUT/$ENHANCED_IMAGE_FILE}"
  logDebug "  $cmd"
  eval "$cmd"
  cp "$ENHANCED_IMAGE_FILE" "$IMAGE_FILE"
  logInfo "Image quality enhanced."
fi




# ---- Build JSON by iterating field lines in .param ---------------------------
logInfo ""
logInfo ""
logInfo "Performing OCR image operations over file $IMAGE_FILE into $OUTPUT_FILE based on layout file $LAYOUT_FILE..."
# Field lines: name|x|y|width|height|lang|psm|whitelist
# Ignore: blank lines, comments (#...), and metadata (WIDTH/HEIGHT/DPI)
JSON_OBJ='{}'
# Pre-filter param lines that look like fields
# - skip empty or comment lines
# - skip lines beginning with OUTPUT=, IMAGE_DESKEW_RECTIFICATION_SCRIPT=, IMAGE_CROP_WORK_ZONE_SCRIPT=, BASE_IMAGE_WORK_ZONE_WIDTH=, BASE_IMAGE_WORK_ZONE_HEIGHT=, IMAGE_ENHANCE_CMD=
while IFS='' read -r line; do
  # Skip empty lines and comments
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
  # Skip metadata keys
  [[ "$line" =~ ^(OUTPUT|IMAGE_DESKEW_RECTIFICATION_SCRIPT|IMAGE_CROP_WORK_ZONE_SCRIPT|BASE_IMAGE_WORK_ZONE_WIDTH|BASE_IMAGE_WORK_ZONE_HEIGHT|IMAGE_ENHANCE_CMD)= ]] && continue
  # Must contain at least 7 pipes (8 columns)
  [[ "$line" != *"|"* ]] && continue
  IFS='|' read -r name x y w h lang psm whitelist <<< "$line"

  # Basic sanity checks
  if [[ -z "${name:-}" || -z "${x:-}" || -z "${y:-}" || -z "${w:-}" || -z "${h:-}" ]]; then
    logWarn "WARNING: Skipping malformed field metadata description. Line: $line" >&2
    continue
  fi
  # Extrapolate coordinates based on actual image work zone dimensions
  xp=$(awk "BEGIN {printf \"%d\", $x * $IMAGE_X_EXTRAPOLATION_FACTOR}")
  yp=$(awk "BEGIN {printf \"%d\", $y * $IMAGE_Y_EXTRAPOLATION_FACTOR}")
  wp=$(awk "BEGIN {printf \"%d\", $w * $IMAGE_X_EXTRAPOLATION_FACTOR}")
  hp=$(awk "BEGIN {printf \"%d\", $h * $IMAGE_Y_EXTRAPOLATION_FACTOR}")
  if [[ -z "$DEBUG_MODE" ]]; then
    logInfo "  Field: $name"
  fi
  if [[ -n "$DEBUG_MODE" ]]; then
    debugInfo=$(printf "  Field: %-28s x:%5s (%5s)  y:%5s (%5s)  w:%5s (%5s)  h:%5s (%5s)" "$name" "$x" "$xp" "$y" "$yp" "$w" "$wp" "$h" "$hp");
    logDebug "$debugInfo"
  fi
  # Run OCR for this field
  value="$(ocr_field "$name" "$xp" "$yp" "$wp" "$hp" "${lang:-}" "${psm:-}" "${whitelist:-}")"
  # Safely add key/value to JSON object
  JSON_OBJ="$(jq --arg k "$name" --arg v "$value" '. + {($k): $v}' <<< "$JSON_OBJ")"
done < <(sed -e 's/[[:space:]]\+$//' "$LAYOUT_FILE")
logInfo "OCR operations completed."




# ---- Generate output file ----------------------------------------------------
logInfo ""
logInfo ""
logInfo "Generating output file $OUTPUT_FILE..."
echo "$JSON_OBJ" | jq . > "$OUTPUT_FILE"
logInfo "Output file generated:"
logInfo ""
[[ -z "$QUIET_MODE" ]] && cat $OUTPUT_FILE
logInfo ""
logInfo ""
logInfo ""
logInfo ""
logInfo "All done!... have a nice day!"
[[ -z "$QUIET_MODE" ]] && { echo ""; echo ""; }
exit 0

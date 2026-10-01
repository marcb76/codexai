#!/bin/bash

# --------------------------------------------------
# tec-ocr-pre-convert-to-png-ve-cedula.sh
# Convert input image to png if needed
# Supports pdf (first page), jpg and jpeg formats
# --------------------------------------------------




# ---- Helper: print usage and exit --------------------------------------------
usage() {
    local message="$1"
    if [ "$message" != "" ]; then
        echo "[ERROR] $message" >&2
    fi
    logInfo "Usage: $0 --input_file=<input_file> [--output_file=<output_file>] [--quiet] [--debug] [--help]"
    logInfo "If output_file is omitted, it will be derived as input_file.png"
    logInfo "If --quiet is provided, minimal output will be shown."
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







# ------------------------------------------------------------------------------
# ---- Entry point -------------------------------------------------------------
# ---- Check dependencies ------------------------------------------------------
need_cmd convert


# ---- Parse arguments ---------------------------------------------------------
QUIET_MODE=""
DEBUG_MODE=""
for arg in "$@"; do
  case "$arg" in
    --quiet)         QUIET_MODE="1";;
  esac
done
[[ -z "$QUIET_MODE" ]] && { clear; echo ""; echo ""; }
logInfo "tec-ocr-pre-convert-to-png-ve-cedula.sh"
logInfo "Parsing arguments..."
INPUT_FILE=""
OUTPUT_FILE=""
QUIET_FLAG=""
DEBUG_FLAG=""
for arg in "$@"; do
  case "$arg" in
    --input_file=*)  INPUT_FILE="${arg#*=}";;
    --output_file=*) OUTPUT_FILE="${arg#*=}";;
    --quiet)         QUIET_MODE="1";;
    --debug)         DEBUG_MODE="1";;
    --help)          usage "";;
    *)               usage "Invalid arguments: Unknown argument $arg";;
  esac
done
[[   -z "$INPUT_FILE" ]] && usage "Invalid arguments: --input_file is required."
[[ ! -z "$DEBUG_MODE" ]] && DEBUG_FLAG="--debug"
[[ ! -z "$QUIET_MODE" ]] && QUIET_FLAG="--quiet"

# ---- Derive output filename if not provided ----------------------------------
[[ -z "$OUTPUT_FILE" ]] && OUTPUT_FILE="${INPUT_FILE%.*}.png"


# ---- Validate input files ----------------------------------------------------
logInfo "Validating input files..."
if [[ ! -f "$INPUT_FILE" ]]; then
  logError "input_file '$INPUT_FILE' not found."
fi
if [[ -f "$OUTPUT_FILE" ]]; then
  logWarn "output_file '$OUTPUT_FILE' already exists. It will be overwritten."
fi


# ---- Convert input image to png if needed ------------------------------------
logInfo "Converting $INPUT_FILE to PNG format..."
INPUT_FILE_EXT="${INPUT_FILE##*.}"
INPUT_FILE_EXT="${INPUT_FILE_EXT,,}"
if [[ "$INPUT_FILE_EXT" == "png" ]]; then
  logInfo "input_file is already a PNG... no conversion needed... only dpi and quality enhancement."
  convert -density 300 "$INPUT_FILE" -quality 100 "$OUTPUT_FILE"
  if [[ "$INPUT_FILE" != "$OUTPUT_FILE" ]]; then
    cp "$INPUT_FILE" "$OUTPUT_FILE"
  fi
elif [[ "$INPUT_FILE_EXT" == "pdf" ]]; then
  # Convert first page of PDF to PNG
  logDebug "convert -density 96 "$INPUT_FILE"[0] -quality 100 "$OUTPUT_FILE""
  convert -density 300 "$INPUT_FILE"[0] -quality 100 "$OUTPUT_FILE"
elif [[ "$INPUT_FILE_EXT" == "jpg" || "$INPUT_FILE_EXT" == "jpeg" ]]; then
  # Convert JPG/JPEG to PNG
  convert -density 300 "$INPUT_FILE" -quality 100 "$OUTPUT_FILE"
  convert "$INPUT_FILE" "$OUTPUT_FILE"
else
  logError "Unsupported file format. Please provide a PDF, JPG, or JPEG file."
fi

# ---- Output final filename to stdout (if not in quiet mode) ------------------
[[ ! -z "$QUIET_MODE" ]] && echo "$OUTPUT_FILE"
logInfo "All done!... output file is $OUTPUT_FILE"
logInfo "Have a nice day!"
[[ -z "$QUIET_MODE" ]] && { echo ""; echo ""; }
exit 0

#!/bin/bash

# --------------------------------------------------
# tec-ocr-pre-deskew-passport.sh
# Bash wrapper for pre-ocr-deskew-passport.py
# --------------------------------------------------





# ---- Helper: print usage and exit --------------------------------------------
usage() {
    local message="$1"
    if [ "$message" != "" ]; then
        echo "[ERROR] $message" >&2
    fi
    logInfo "Usage: $0 --input_file=<input_file> [--output_file=<output_file>] [--quiet] [--debug] [--help]"
    logInfo "If output_file is omitted, it will be derived as input-filename-deskew.ext"
    logInfo "If --quiet is provided, minimal output will be shown."
    logInfo "If --debug is provided, debug output will be shown; intermediate files will be preserved."
    logInfo "if --hrelp is provided, this help message will be shown."
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
need_cmd python3


# ---- Parse arguments ---------------------------------------------------------
QUIET_MODE=""
DEBUG_MODE=""
for arg in "$@"; do
  case "$arg" in
    --quiet)         QUIET_MODE="1";;
  esac
done
[[ -z "$QUIET_MODE" ]] && { clear; echo ""; echo ""; }
logInfo "tec-ocr-pre-deskew-passport.sh"
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
if [ -z "$OUTPUT_FILE" ]; then
    EXT="${INPUT_FILE##*.}"          # get file extension
    BASENAME="${INPUT_FILE%.*}"      # get base filename
    OUTPUT_FILE="${BASENAME}-deskew.${EXT}"
fi


# ---- Validate input files ----------------------------------------------------
logInfo "Validating input files..."
if [[ ! -f "$INPUT_FILE" ]]; then
  logError "input_file '$INPUT_FILE' not found."
fi
if [[ -f "$OUTPUT_FILE" ]]; then
  logWarn "output_file '$OUTPUT_FILE' already exists. It will be overwritten."
fi


# ---- Call the Python script --------------------------------------------------
PYTHON_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT_NAME="tec-ocr-pre-deskew-passport.py"
if [[ ! -f "$PYTHON_SCRIPT_DIR/$PYTHON_SCRIPT_NAME" ]]; then
    logError "Python script '$PYTHON_SCRIPT_DIR/$PYTHON_SCRIPT_NAME' not found."
fi
logDebug "python3 \"$PYTHON_SCRIPT_DIR/$PYTHON_SCRIPT_NAME\" \"$INPUT_FILE\" \"$OUTPUT_FILE\" $QUIET_FLAG $DEBUG_FLAG"
python3 "$PYTHON_SCRIPT_DIR/$PYTHON_SCRIPT_NAME" "$INPUT_FILE" "$OUTPUT_FILE" $QUIET_FLAG $DEBUG_FLAG
if [ "$?" -ne 0 ]; then
    logError "Error: Python script failed with exit code $?."
fi


# ---- Output final filename to stdout (if not in quiet mode) ------------------
[[ ! -z "$QUIET_MODE" ]] && echo "$OUTPUT_FILE"
logInfo "All done!... output file is $OUTPUT_FILE"
logInfo "Have a nice day!"
[[ -z "$QUIET_MODE" ]] && { echo ""; echo ""; }
exit 0

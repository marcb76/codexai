#!/bin/bash
# =========================================================
# tec-ocr-simulation.sh - Dummy OCR script for Linux/macOS
# Accepts --image, --layout, --output and --quiet
# Writes a dummy JSON file
# =========================================================

# Initialize variables
IMAGE_FILE=""
LAYOUT_FILE=""
OUTPUT_FILE=""
QUIET=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --image)
            IMAGE_FILE="$2"
            shift 2
            ;;
        --layout)
            LAYOUT_FILE="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --quiet)
            QUIET=1
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            shift
            ;;
    esac
done

# Default output file if none specified
if [[ -z "$OUTPUT_FILE" ]]; then
    OUTPUT_FILE="tec-ocr-simulation-output.json"
fi

# Print arguments if not quiet
if [[ $QUIET -eq 0 ]]; then
    echo "Image file: \"$IMAGE_FILE\""
    echo "Layout file: \"$LAYOUT_FILE\""
    echo "Output file: \"$OUTPUT_FILE\""
fi

# Write dummy JSON content
cat > "$OUTPUT_FILE" <<EOF
{
    "field1": "dummy value",
    "field2": 1234
}
EOF

# Completion message
if [[ $QUIET -eq 0 ]]; then
    echo "Dummy OCR finished. Output written to \"$OUTPUT_FILE\""
fi
exit 0

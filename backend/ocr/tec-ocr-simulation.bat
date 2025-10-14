@echo off
setlocal enabledelayedexpansion

REM ====================================================
REM tec-ocr-simulation.bat - Dummy OCR script for Windows
REM Accepts --image, --layout, --output and --quiet
REM Writes a dummy JSON file
REM ====================================================

REM Initialize variables
set "IMAGE_FILE="
set "LAYOUT_FILE="
set "OUTPUT_FILE="
set "QUIET=0"
set "NEXT_ARG="

REM Parse arguments
for %%A in (%*) do (
    set "ARG=%%A"

    REM Detect flags
    if /i "!ARG!"=="--image" (
        set "NEXT_ARG=image"
    ) else if /i "!ARG!"=="--layout" (
        set "NEXT_ARG=layout"
    ) else if /i "!ARG!"=="--output" (
        set "NEXT_ARG=output"
    ) else if /i "!ARG!"=="--quiet" (
        set "QUIET=1"
        set "NEXT_ARG="
    ) else (
        REM Assign value to previous flag
        if "!NEXT_ARG!"=="image" (
            set "IMAGE_FILE=!ARG!"
        ) else if "!NEXT_ARG!"=="layout" (
            set "LAYOUT_FILE=!ARG!"
        ) else if "!NEXT_ARG!"=="output" (
            set "OUTPUT_FILE=!ARG!"
        )
        set "NEXT_ARG="
    )
)

REM Default output file if none specified
if "%OUTPUT_FILE%"=="" set "OUTPUT_FILE=tec-ocr-simulation-output.json"

REM Print arguments if not quiet
if "%QUIET%"=="0" (
    echo Image file: "%IMAGE_FILE%"
    echo Layout file: "%LAYOUT_FILE%"
    echo Output file: "%OUTPUT_FILE%"
)

REM Write dummy JSON content
(
    echo {
    echo     "field1": "dummy value",
    echo     "field2": 1234
    echo }
) > "%OUTPUT_FILE%"

if "%QUIET%"=="0" echo Dummy OCR finished. Output written to "%OUTPUT_FILE%"

exit /b 0

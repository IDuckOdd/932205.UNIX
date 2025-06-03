#!/bin/sh

if [ $# -ne 1 ]; then
    echo "Usage: $0 source_file" >&2
    exit 1
fi

SOURCE_FILE="$1"

if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: File '$SOURCE_FILE' does not exist or is not a regular file" >&2
    exit 2
fi

_ORIGINAL_PWD=$(pwd)
_TEMP_DIR=""

_cleanup_and_exit() {
    if [ -n "$_TEMP_DIR" ] && [ -d "$_TEMP_DIR" ]; then
        rm -rf "$_TEMP_DIR"
    fi
    if [ -n "$_ORIGINAL_PWD" ] && [ "$(pwd)" != "$_ORIGINAL_PWD" ]; then
      cd "$_ORIGINAL_PWD"
    fi
    exit "$1"
}

trap '_cleanup_and_exit 130' INT
trap '_cleanup_and_exit 143' TERM
trap '_cleanup_and_exit $?' EXIT

_TEMP_DIR=$(mktemp -d)
if [ $? -ne 0 ] || [ ! -d "$_TEMP_DIR" ]; then
    echo "Error: Failed to create temp directory" >&2
    _cleanup_and_exit 3
fi

_OUTPUT_FILENAME=""

case "$SOURCE_FILE" in
    *.c)
        ;;
    *.tex)
        ;;
    *.cpp|*.cxx|*.cc)
        ;;
    *)
        echo "Error: Unsupported file type for '$SOURCE_FILE'. Supported: .c, .cpp, .tex" >&2
        _cleanup_and_exit 4
        ;;
esac

_OUTPUT_FILENAME=$(awk -F '&Output:' '
    NF > 1 {
        output_val = $2;
        sub(/^[[:space:]]+/, "", output_val);
        sub(/[[:space:]]*\*\/[[:space:]]*$/, "", output_val);
        sub(/[[:space:]]*\/\/.*/, "", output_val);
        sub(/[[:space:]]*%.*/, "", output_val);
        sub(/[[:space:]]+$/, "", output_val);
        if (output_val != "") {
            print output_val;
            exit;
        }
    }
' "$SOURCE_FILE")


if [ -z "$_OUTPUT_FILENAME" ]; then
    echo "Error: No output filename specified with &Output: in '$SOURCE_FILE'" >&2
    _cleanup_and_exit 5
fi

if ! cp "$SOURCE_FILE" "$_TEMP_DIR/"; then
    echo "Error: Failed to copy '$SOURCE_FILE' to temporary directory" >&2
    _cleanup_and_exit 6
fi

if ! cd "$_TEMP_DIR"; then
    echo "Error: Failed to change directory to '$_TEMP_DIR'" >&2
    _cleanup_and_exit 7
fi

_SOURCE_BASENAME=$(basename "$SOURCE_FILE")

case "$SOURCE_FILE" in
    *.c)
        if ! cc "$_SOURCE_BASENAME" -o "$_OUTPUT_FILENAME"; then
            echo "Error: C compilation failed for '$_SOURCE_BASENAME'" >&2
            _cleanup_and_exit 8
        fi
        ;;
    *.cpp|*.cxx|*.cc)
        if ! c++ "$_SOURCE_BASENAME" -o "$_OUTPUT_FILENAME"; then
            echo "Error: C++ compilation failed for '$_SOURCE_BASENAME'" >&2
            _cleanup_and_exit 12
        fi
        ;;
    *.tex)
        _TEX_JOBNAME=$(echo "$_OUTPUT_FILENAME" | sed 's/\.pdf$//')
        _EXPECTED_PDF_BY_LATEX="${_TEX_JOBNAME}.pdf"

        if ! pdflatex -interaction=nonstopmode -jobname="$_TEX_JOBNAME" "$_SOURCE_BASENAME" >/dev/null || \
           ! pdflatex -interaction=nonstopmode -jobname="$_TEX_JOBNAME" "$_SOURCE_BASENAME" >/dev/null; then
            echo "Error: TeX compilation failed for '$_SOURCE_BASENAME'." >&2
            if [ -f "$_TEX_JOBNAME.log" ]; then
                echo "--- TeX Log ($_TEX_JOBNAME.log) ---" >&2
                cat "$_TEX_JOBNAME.log" >&2
                echo "--- End TeX Log ---" >&2
            fi
            _cleanup_and_exit 10
        fi
        
        if [ "$_EXPECTED_PDF_BY_LATEX" != "$_OUTPUT_FILENAME" ] && [ -f "$_EXPECTED_PDF_BY_LATEX" ]; then
            if ! mv "$_EXPECTED_PDF_BY_LATEX" "$_OUTPUT_FILENAME"; then
                 echo "Error: Failed to rename '$_EXPECTED_PDF_BY_LATEX' to '$_OUTPUT_FILENAME'" >&2
                 _cleanup_and_exit 13
            fi
        fi
        ;;
esac

if [ ! -f "$_OUTPUT_FILENAME" ]; then
    echo "Error: Compiled file '$_OUTPUT_FILENAME' not found in temporary directory after build" >&2
    _cleanup_and_exit 9
fi

cd "$_ORIGINAL_PWD"

_TARGET_DIR_FOR_OUTPUT=$(dirname "$SOURCE_FILE")

if ! mv "$_TEMP_DIR/$_OUTPUT_FILENAME" "$_TARGET_DIR_FOR_OUTPUT/"; then
    echo "Error: Failed to move '$_OUTPUT_FILENAME' to '$_TARGET_DIR_FOR_OUTPUT/'" >&2
    _cleanup_and_exit 11
fi

echo "Success: Output file '$_OUTPUT_FILENAME' created in '$_TARGET_DIR_FOR_OUTPUT/'" >&2
_cleanup_and_exit 0

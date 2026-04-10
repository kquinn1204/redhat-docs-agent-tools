#!/bin/bash
# strip-internal.sh
#
# Strips internal-only content from telco RDS monolithic AsciiDoc files.
# Removes:
#   1. All content between // tag::internal[] and // end::internal[] (inclusive)
#   2. Top-level product attribute definitions (provided by common-attributes.adoc)
#
# Usage: strip-internal.sh <input-file> [--output-dir <dir>]

set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") <input-file> [--output-dir <dir>]

Strip internal-only content from a telco RDS AsciiDoc file.

Arguments:
  <input-file>         Path to the monolithic RDS AsciiDoc file
  --output-dir <dir>   Output directory (default: current directory)

Output:
  Writes stripped file to <output-dir>/<original-filename>
EOF
    exit 1
}

# Parse arguments
if [ $# -lt 1 ]; then
    usage
fi

INPUT_FILE="$1"
shift

OUTPUT_DIR="."

while [ $# -gt 0 ]; do
    case "$1" in
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        *)
            echo "Error: Unknown argument: $1" >&2
            usage
            ;;
    esac
done

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file not found: $INPUT_FILE" >&2
    exit 1
fi

FILENAME=$(basename "$INPUT_FILE")
mkdir -p "$OUTPUT_DIR"
OUTPUT_FILE="$OUTPUT_DIR/$FILENAME"

# Product attributes to strip (defined at top of monolith, provided by common-attributes.adoc downstream)
STRIP_ATTRS=(
    ":product-title:"
    ":product-version:"
    ":imagesdir:"
    ":rh-storage:"
    ":cgu-operator:"
    ":rh-rhacm:"
    ":sno:"
    ":ztp:"
)

# Build sed pattern for attribute stripping
ATTR_PATTERN=""
for attr in "${STRIP_ATTRS[@]}"; do
    if [ -z "$ATTR_PATTERN" ]; then
        ATTR_PATTERN="^${attr}"
    else
        ATTR_PATTERN="${ATTR_PATTERN}|^${attr}"
    fi
done

# Process the file:
# 1. Remove // tag::internal[] ... // end::internal[] blocks
# 2. Remove top-level attribute definitions
# 3. Collapse runs of 3+ blank lines to 2

internal_blocks=0
in_internal=0
total_lines=0
stripped_lines=0

{
    while IFS= read -r line || [ -n "$line" ]; do
        total_lines=$((total_lines + 1))

        # Check for internal block start
        if [[ "$line" == "// tag::internal[]" ]]; then
            in_internal=1
            internal_blocks=$((internal_blocks + 1))
            stripped_lines=$((stripped_lines + 1))
            continue
        fi

        # Check for internal block end
        if [[ "$line" == "// end::internal[]" ]]; then
            in_internal=0
            stripped_lines=$((stripped_lines + 1))
            continue
        fi

        # Skip lines inside internal blocks
        if [ $in_internal -eq 1 ]; then
            stripped_lines=$((stripped_lines + 1))
            continue
        fi

        # Skip top-level attribute definitions
        skip=0
        for attr in "${STRIP_ATTRS[@]}"; do
            if [[ "$line" == ${attr}* ]]; then
                skip=1
                stripped_lines=$((stripped_lines + 1))
                break
            fi
        done
        if [ $skip -eq 1 ]; then
            continue
        fi

        echo "$line"
    done
} < "$INPUT_FILE" > "$OUTPUT_FILE.tmp"

# Collapse runs of 3+ blank lines to 2
awk '
    /^$/ { blank++; next }
    {
        if (blank > 0) {
            n = (blank > 2) ? 2 : blank
            for (i = 0; i < n; i++) print ""
            blank = 0
        }
        print
    }
    END {
        if (blank > 0) {
            n = (blank > 2) ? 2 : blank
            for (i = 0; i < n; i++) print ""
        }
    }
' "$OUTPUT_FILE.tmp" > "$OUTPUT_FILE"

rm -f "$OUTPUT_FILE.tmp"

echo "Stripped: $INPUT_FILE -> $OUTPUT_FILE"
echo "  Internal blocks removed: $internal_blocks"
echo "  Lines stripped: $stripped_lines (of $total_lines total)"
echo "  Output lines: $(wc -l < "$OUTPUT_FILE")"

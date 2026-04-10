#!/usr/bin/env python3
"""
split-monolith.py

Splits a stripped telco RDS monolithic AsciiDoc file into individual module
files based on [id="..."] markers. Each section becomes a separate module
with proper Red Hat modular documentation headers.

Usage:
    split-monolith.py <input-file> --output-dir <dir> [--context <ctx>] [--rds-type <type>]

Arguments:
    <input-file>         Stripped monolithic AsciiDoc file
    --output-dir <dir>   Directory to write module files
    --context <ctx>      Context variable for _{context} suffix (default: derived from filename)
    --rds-type <type>    RDS type: core, ran, or hub (default: derived from filename)
"""

import argparse
import os
import re
import sys
import json


def detect_content_type(lines):
    """Detect whether a section is CONCEPT, PROCEDURE, or REFERENCE."""
    text = "\n".join(lines)

    # REFERENCE: sections with CR tables or structured reference data
    if re.search(r"reference.*(cr|configuration|custom resource)", text, re.IGNORECASE):
        return "REFERENCE"
    if text.count("|===") >= 2:  # Has a table
        # Tables with CR references are REFERENCE
        if re.search(r"(CR|Custom Resource|reference CR)", text, re.IGNORECASE):
            return "REFERENCE"

    # PROCEDURE: sections with numbered steps
    numbered_steps = re.findall(r"^\. \w", text, re.MULTILINE)
    if len(numbered_steps) >= 2:
        return "PROCEDURE"

    # Default to CONCEPT for RDS content (descriptions, engineering considerations)
    return "CONCEPT"


def heading_level(line):
    """Count the number of = characters at the start of a heading line."""
    match = re.match(r"^(=+) ", line)
    if match:
        return len(match.group(1))
    return 0


def parse_sections(lines):
    """Parse the monolith into sections delimited by [id="..."] markers."""
    sections = []
    current_section = None
    preamble_lines = []

    i = 0
    while i < len(lines):
        line = lines[i]

        # Detect [id="..."] marker
        id_match = re.match(r'^\[id="([^"]+)"\]', line)
        if id_match:
            # Save previous section
            if current_section:
                sections.append(current_section)

            section_id = id_match.group(1)

            # Next non-empty line should be the heading
            heading_line = ""
            hlevel = 0
            j = i + 1
            while j < len(lines):
                if lines[j].strip():
                    if re.match(r"^=+ ", lines[j]):
                        heading_line = lines[j]
                        hlevel = heading_level(lines[j])
                    break
                j += 1

            current_section = {
                "id": section_id,
                "heading": heading_line,
                "level": hlevel,
                "start_line": i,
                "lines": [line],  # Include the [id=] line
            }
            i += 1
            continue

        if current_section:
            current_section["lines"].append(line)
        else:
            preamble_lines.append(line)

        i += 1

    # Don't forget the last section
    if current_section:
        sections.append(current_section)

    return preamble_lines, sections


def section_to_module_name(section_id, rds_type):
    """Convert a section ID to a module filename."""
    # The IDs already have the telco-core/telco-ran/telco-hub prefix
    return f"{section_id}.adoc"


def write_module(section, output_dir, context):
    """Write a single section as a module file."""
    section_id = section["id"]
    lines = section["lines"]
    hlevel = section["level"]

    content_type = detect_content_type(lines)

    module_lines = []

    # Add modular docs header
    module_lines.append(f":_mod-docs-content-type: {content_type}")

    # Process lines
    for line in lines:
        # Update [id="..."] to append _{context}
        id_match = re.match(r'^\[id="([^"]+)"\]', line)
        if id_match:
            original_id = id_match.group(1)
            module_lines.append(f'[id="{original_id}_{{context}}"]')
            continue

        # Demote heading to = (level 1) — leveloffset in the assembly handles nesting
        heading_match = re.match(r"^(=+) (.+)$", line)
        if heading_match and heading_level(line) == hlevel:
            title = heading_match.group(2)
            module_lines.append(f"= {title}")
            continue

        # Demote sub-headings relative to the section level
        if heading_match:
            current_level = len(heading_match.group(1))
            relative_level = current_level - hlevel + 1
            new_prefix = "=" * relative_level
            title = heading_match.group(2)
            module_lines.append(f"{new_prefix} {title}")
            continue

        module_lines.append(line)

    # Write the module file
    filename = section_to_module_name(section_id, None)
    filepath = os.path.join(output_dir, filename)

    with open(filepath, "w") as f:
        f.write("\n".join(module_lines))
        if not module_lines[-1] == "":
            f.write("\n")

    return {
        "filename": filename,
        "id": section_id,
        "level": hlevel,
        "content_type": content_type,
        "heading": section["heading"].strip().lstrip("= "),
    }


def main():
    parser = argparse.ArgumentParser(
        description="Split a telco RDS monolith into modular AsciiDoc files"
    )
    parser.add_argument("input_file", help="Path to the stripped monolithic AsciiDoc file")
    parser.add_argument("--output-dir", required=True, help="Directory to write module files")
    parser.add_argument("--context", help="Context variable (default: derived from filename)")
    parser.add_argument(
        "--rds-type",
        choices=["core", "ran", "hub"],
        help="RDS type (default: derived from filename)",
    )

    args = parser.parse_args()

    if not os.path.isfile(args.input_file):
        print(f"Error: Input file not found: {args.input_file}", file=sys.stderr)
        sys.exit(1)

    # Derive context and rds-type from filename if not provided
    basename = os.path.basename(args.input_file)
    if not args.context:
        if "core" in basename:
            args.context = "telco-core"
        elif "ran" in basename:
            args.context = "telco-ran"
        elif "hub" in basename:
            args.context = "telco-hub"
        else:
            args.context = "telco-core"

    if not args.rds_type:
        if "core" in basename:
            args.rds_type = "core"
        elif "ran" in basename:
            args.rds_type = "ran"
        elif "hub" in basename:
            args.rds_type = "hub"
        else:
            args.rds_type = "core"

    # Read input
    with open(args.input_file, "r") as f:
        lines = f.read().splitlines()

    # Parse into sections
    preamble_lines, sections = parse_sections(lines)

    # Skip the document title section (level 1 = heading) — it becomes the assembly title
    # Keep all level 2+ sections as modules
    title_section = None
    module_sections = []
    for s in sections:
        if s["level"] == 1:
            title_section = s
        else:
            module_sections.append(s)

    # Create output directory
    os.makedirs(args.output_dir, exist_ok=True)

    # Write modules
    manifest = []
    for section in module_sections:
        entry = write_module(section, args.output_dir, args.context)
        manifest.append(entry)
        print(f"  Created: {entry['filename']} ({entry['content_type']}, level {entry['level']})")

    # Write manifest
    manifest_path = os.path.join(args.output_dir, "manifest.json")
    manifest_data = {
        "context": args.context,
        "rds_type": args.rds_type,
        "title": title_section["heading"].strip().lstrip("= ") if title_section else "Telco RDS",
        "title_id": title_section["id"] if title_section else "",
        "modules": manifest,
    }
    with open(manifest_path, "w") as f:
        json.dump(manifest_data, f, indent=2)

    print(f"\nSplit complete: {len(manifest)} modules written to {args.output_dir}")
    print(f"Manifest: {manifest_path}")


if __name__ == "__main__":
    main()

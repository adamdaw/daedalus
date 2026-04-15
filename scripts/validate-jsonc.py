#!/usr/bin/env python3
"""Validate JSONC (JSON with Comments) files.

Strips single-line // comments using a string-context-aware state machine,
then validates the result with Python's json.loads().

The state machine tracks whether the current position is inside a JSON string,
so // in a string value (e.g. "https://example.com") is preserved correctly
and not mistaken for a comment.

Usage: python3 scripts/validate-jsonc.py file1.jsonc [file2.jsonc ...]
Exit code 0 if all files are valid; 1 if any file has a JSON syntax error.

Reference: Dev Container spec (JSONC) — https://containers.dev/implementors/json_reference/
"""
import json
import sys


def strip_line_comments(text: str) -> str:
    """Return text with // line comments removed, preserving string content."""
    out = []
    i = 0
    in_str = False
    while i < len(text):
        ch = text[i]
        if in_str:
            out.append(ch)
            if ch == "\\":        # escape sequence: consume next char verbatim
                i += 1
                out.append(text[i])
            elif ch == '"':
                in_str = False
        elif ch == '"':
            in_str = True
            out.append(ch)
        elif ch == "/" and i + 1 < len(text) and text[i + 1] == "/":
            while i < len(text) and text[i] != "\n":
                i += 1
            out.append("\n")
            continue
        else:
            out.append(ch)
        i += 1
    return "".join(out)


def main() -> None:
    failed = False
    for path in sys.argv[1:]:
        try:
            with open(path, encoding="utf-8") as fh:
                text = fh.read()
            json.loads(strip_line_comments(text))
        except json.JSONDecodeError as exc:
            print(f"{path}: {exc}")
            failed = True
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()

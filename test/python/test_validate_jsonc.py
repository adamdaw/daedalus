"""Tests for scripts/validate-jsonc.py.

Covers both strip_line_comments() and main() (via subprocess).

References:
    pytest — https://docs.pytest.org
    subprocess — https://docs.python.org/3/library/subprocess.html
"""
import subprocess
import sys
from pathlib import Path

SCRIPT = str(Path(__file__).parent.parent.parent / "scripts" / "validate-jsonc.py")


# ---------------------------------------------------------------------------
# strip_line_comments tests
# ---------------------------------------------------------------------------


class TestStripLineComments:
    """Tests for the strip_line_comments function."""

    def test_removes_trailing_comment(self, validate_jsonc):
        result = validate_jsonc.strip_line_comments('{"a": 1} // comment')
        assert result == '{"a": 1} \n'

    def test_preserves_url_inside_string(self, validate_jsonc):
        text = '{"url": "https://example.com"}'
        assert validate_jsonc.strip_line_comments(text) == text

    def test_handles_multiple_comment_lines(self, validate_jsonc):
        text = '{"a": 1} // first\n{"b": 2} // second\n'
        result = validate_jsonc.strip_line_comments(text)
        # The state machine emits a \n when it hits //, then also passes through
        # the original \n — so each commented line produces a double newline.
        assert result == '{"a": 1} \n\n{"b": 2} \n\n'

    def test_empty_string(self, validate_jsonc):
        assert validate_jsonc.strip_line_comments("") == ""

    def test_escaped_quotes_inside_strings(self, validate_jsonc):
        text = '{"msg": "say \\"hello\\""}'
        result = validate_jsonc.strip_line_comments(text)
        assert result == text

    def test_line_with_only_comment(self, validate_jsonc):
        result = validate_jsonc.strip_line_comments("// just a comment")
        assert result == "\n"

    def test_pure_json_unchanged(self, validate_jsonc):
        text = '{"name": "test", "count": 42, "nested": {"key": "val"}}'
        assert validate_jsonc.strip_line_comments(text) == text


# ---------------------------------------------------------------------------
# main() tests (via subprocess)
# ---------------------------------------------------------------------------


class TestMain:
    """Tests for main() invoked as a subprocess."""

    def test_valid_jsonc_exits_zero(self, tmp_path):
        f = tmp_path / "valid.jsonc"
        f.write_text('{"name": "test"} // comment\n')
        result = subprocess.run(
            [sys.executable, SCRIPT, str(f)],
            capture_output=True, text=True,
        )
        assert result.returncode == 0

    def test_invalid_json_exits_one(self, tmp_path):
        f = tmp_path / "invalid.jsonc"
        f.write_text('{"name": }')
        result = subprocess.run(
            [sys.executable, SCRIPT, str(f)],
            capture_output=True, text=True,
        )
        assert result.returncode == 1
        assert str(f) in result.stdout

    def test_jsonc_with_comments_validates(self, tmp_path):
        f = tmp_path / "commented.jsonc"
        f.write_text(
            '// top-level comment\n'
            '{\n'
            '  "key": "value" // inline\n'
            '}\n'
        )
        result = subprocess.run(
            [sys.executable, SCRIPT, str(f)],
            capture_output=True, text=True,
        )
        assert result.returncode == 0

    def test_multiple_files_one_invalid_exits_one(self, tmp_path):
        good = tmp_path / "good.jsonc"
        good.write_text('{"ok": true}\n')
        bad = tmp_path / "bad.jsonc"
        bad.write_text('{"broken": }\n')
        result = subprocess.run(
            [sys.executable, SCRIPT, str(good), str(bad)],
            capture_output=True, text=True,
        )
        assert result.returncode == 1

    def test_file_not_found_exits_nonzero(self, tmp_path):
        missing = tmp_path / "nonexistent.jsonc"
        result = subprocess.run(
            [sys.executable, SCRIPT, str(missing)],
            capture_output=True, text=True,
        )
        assert result.returncode != 0

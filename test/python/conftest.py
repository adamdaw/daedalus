"""Pytest configuration for validate-jsonc.py tests.

References:
    pytest — https://docs.pytest.org
    importlib — https://docs.python.org/3/library/importlib.html
"""
import importlib.util
import sys
from pathlib import Path

import pytest


@pytest.fixture
def validate_jsonc():
    """Import the validate-jsonc.py module (hyphen in filename requires importlib)."""
    spec = importlib.util.spec_from_file_location(
        "validate_jsonc",
        Path(__file__).parent.parent.parent / "scripts" / "validate-jsonc.py",
    )
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

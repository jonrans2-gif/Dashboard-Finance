#!/usr/bin/env bash
# Runs the automated test suite headlessly. Exit code = number of failed checks.
cd "$(dirname "$0")"
godot --headless --path . --fixed-fps 60 res://tests/test_runner.tscn "$@"

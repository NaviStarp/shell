#!/usr/bin/env bash
# ==============================================================================
# lock.sh - Launches the standalone Quickshell Lockscreen
# ==============================================================================
exec quickshell -p "$HOME/.config/quickshell/lockscreen/shell.qml" "$@"

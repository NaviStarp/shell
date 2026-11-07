#!/usr/bin/env bash
# ==============================================================================
# auth.sh - Quickshell Standalone Lockscreen Authenticator
# ==============================================================================
set -euo pipefail

# Read password from stdin
read -r PASSWORD || exit 1

# Try setuid unix_chkpwd (NixOS wrapper or system shadow helper)
for bin in /run/wrappers/bin/unix_chkpwd /usr/sbin/unix_chkpwd /sbin/unix_chkpwd; do
    if [ -x "$bin" ]; then
        if printf "%s\0" "$PASSWORD" | "$bin" "$USER" nullok 2>/dev/null; then
            exit 0
        else
            exit 1
        fi
    fi
done

# Fallback to su if unix_chkpwd not found
if printf "%s\n" "$PASSWORD" | su -c "true" "$USER" 2>/dev/null; then
    exit 0
fi

exit 1

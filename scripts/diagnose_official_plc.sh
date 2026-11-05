#!/usr/bin/env bash
# Read-only Pine-Apple PLC diagnosis. Run on Ubuntu host in official compose directory.
set -u
echo '=== Docker services ==='
docker compose ps 2>&1 || true
echo '=== OpenPLC runtime logs ==='
docker compose logs --tail=140 irs-openplc-runtime 2>&1 | grep -Ei 'libplc|state transition|running|modbus|compile|error|failed' || true
echo '=== PLC runtime processes ==='
docker exec openplc-runtime bash -c 'for p in /proc/[0-9]*/comm; do printf "%s: " "$p"; cat "$p" 2>/dev/null; done' 2>&1 | head -45 || true
echo '=== Compiled PLC libraries ==='
docker exec openplc-runtime bash -c 'find / -name "libplc_*.so" 2>/dev/null | head -20' 2>&1 || true
echo '=== Editor service availability ==='
docker compose config --services 2>/dev/null | grep -Ei 'openplc|simulation' || true
echo '=== Local PLC source files (excluding protected workspace) ==='
find . -path './workspace' -prune -o -type f \( -iname '*.st' -o -iname '*.ld' -o -iname '*.plc' \) -print 2>/dev/null | head -50
echo '=== Interpretation ==='
echo 'No libplc_*.so plus RUNNING transition failed means no active compiled PLC program.'
echo 'Do not assume healthy Docker means active PLC logic.'

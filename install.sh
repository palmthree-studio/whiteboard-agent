#!/usr/bin/env bash
# install.sh — Whiteboard Agent installer (Wendy mascot + auth + binary)
# Usage: curl -fsSL https://raw.githubusercontent.com/palmthree-studio/whiteboard-agent/main/install.sh | bash

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# ANSI colors (fallback if terminal does not support them)
# ─────────────────────────────────────────────────────────────────────────────

if [[ -n "${NO_COLOR:-}" ]] || [[ "${TERM:-dumb}" == "dumb" ]] || [[ ! -t 1 ]]; then
  C_RESET=""
  C_VIOLET=""
  C_BLUE=""
  C_RED=""
  C_GREEN=""
  C_YELLOW=""
  C_BOLD=""
  C_DIM=""
else
  C_RESET=$'\033[0m'
  C_VIOLET=$'\033[1;35m'
  C_BLUE=$'\033[1;36m'
  C_RED=$'\033[1;31m'
  C_GREEN=$'\033[1;32m'
  C_YELLOW=$'\033[1;33m'
  C_BOLD=$'\033[1m'
  C_DIM=$'\033[2m'
fi

# ─────────────────────────────────────────────────────────────────────────────
# Wendy logo
# ─────────────────────────────────────────────────────────────────────────────

_wendy_decode() {
  if [[ "${OSTYPE}" == "darwin"* ]]; then
    base64 -D
  else
    base64 -d
  fi
}

show_wendy() {
  local art_width=78
  local cols
  cols=$(tput cols 2>/dev/null || echo 80)
  local pad=$(( (cols - art_width) / 2 ))
  [[ $pad -lt 0 ]] && pad=0
  local indent
  indent=$(printf '%*s' "$pad" '')

  read -r -d '' _WENDY << 'WENDYEND' || true
G1swbRtbMG0gICAgICAgICAgICAgICAgICAgICAgICAgICAbWzM4OzU7MTA5beKUjBtbMzg7NTsxMDlt4pWUG1szODs1Ozc0beKWkRtbMzg7NTsxMDlt4pWTICAgICAgICAgICAgICAgIBtbMzg7NTsxMzlt4pWUG1szODs1OzEzNG3ilpEbWzM4OzU7MTM5beKVlBtbMzg7NTsxMzlt4pSMG1swbQobWzBtG1swbSAgICAgICAgICAgICAgICAgICAgIBtbMzg7NTsxMDlt4pSMG1szODs1OzEwOW3ilZQbWzM4OzU7NzRt4paRG1szODs1Ozc0beKWkRtbMzg7NTs3NG3ilpEbWzM4OzU7NzRt4paR4paR4paR4paR4paRG1szODs1OzEwOW3ilJAgICAgICAgICAgICAgIBtbMzg7NTsxMzRt4paRG1szODs1OzEzNG3ilpEbWzM4OzU7MTM0beKWkeKWkeKWkeKWkeKWkRtbMzg7NTsxMzRt4paRG1szODs1OzEzNG3ilpEbWzM4OzU7MTM5beKVlBtbMzg7NTsxMzlt4pSMG1swbQobWzBtG1swbSAgICAgICAgICAgICAgIBtbMzg7NTsxMDlt4pSMG1szODs1OzEwOW3ilZQbWzM4OzU7NzRt4paRG1szODs1Ozc0beKWkRtbMzg7NTs3NG3ilpEbWzM4OzU7NzRt4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paRICAgICAgICAgICAgIBtbMzg7NTsxMzlt4pSMG1szODs1OzEzNG3ilpEbWzM4OzU7MTM0beKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkRtbMzg7NTsxMzRt4paRG1szODs1OzEzNG3ilpEbWzM4OzU7MTM5beKVlBtbMzg7NTsxMzlt4pSMG1swbQobWzBtG1swbSAgICAgICAgIBtbMzg7NTsxMDlt4pSMG1szODs1OzEwOW3ilZQbWzM4OzU7NzRt4paRG1szODs1Ozc0beKWkRtbMzg7NTs3NG3ilpEbWzM4OzU7NzRt4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paRG1szODs1Ozc0beKWkSAgICAgICAgICAgG1szODs1OzEzOW3ilIwbWzM4OzU7MTM0beKWkRtbMzg7NTsxMzRt4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paRG1szODs1OzEzNG3ilpEbWzM4OzU7MTM0beKWkRtbMzg7NTsxMzlt4pWUG1szODs1OzEzOW3ilIwbWzBtChtbMG0bWzBtICAgG1szODs1OzEwOW3ilIwbWzM4OzU7MTA5beKVlBtbMzg7NTs3NG3ilpEbWzM4OzU7NzRt4paRG1szODs1Ozc0beKWkRtbMzg7NTs3NG3ilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpEbWzM4OzU7NzRt4paRICAgICAgICAgIBtbMzg7NTsxMzRt4paRG1szODs1OzEzNG3ilpEbWzM4OzU7MTM0beKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkRtbMzg7NTsxMzRt4paRG1szODs1OzEzNG3ilpEbWzM4OzU7MTM0beKWkRtbMzg7NTsxMzlt4pWUG1szODs1OzEzOW3ilIwbWzBtChtbMG0bWzBtG1szODs1OzEwOW3ilZIbWzM4OzU7NzRt4paRG1szODs1Ozc0beKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkRtbMzg7NTs3NG3ilpEgICAgICAgIBtbMzg7NTsxMzRt4paRG1szODs1OzEzNG3ilpEbWzM4OzU7MTM0beKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkRtbMzg7NTsxMzRt4paRG1szODs1OzEzOW3ilIAbWzBtChtbMG0bWzBtIBtbMzg7NTs3NG3ilpEbWzM4OzU7NzRt4paRG1szODs1Ozc0beKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkRtbMzg7NTs3NG3ilpEbWzM4OzU7MTAybeKWkRtbMzg7NTsxMDJt4paRG1szODs1OzEwMm3ilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpEbWzM4OzU7MTAybeKUkBtbMzg7NTsxNDRt4pSMG1szODs1OzE0NG3ilIzilIzilIzilIzilIwbWzM4OzU7MTM4beKVlBtbMzg7NTsxMzJt4paRG1szODs1OzEzMm3ilpHilpHilpHilpHilpHilpHilpHilpEbWzM4OzU7MTMzbeKWkRtbMzg7NTsxMzRt4paRG1szODs1OzEzNG3ilpEbWzM4OzU7MTM0beKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkRtbMzg7NTsxMzRt4paRG1swbQobWzBtG1swbSAgG1szODs1Ozc0beKWkRtbMzg7NTs3NG3ilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpEbWzM4OzU7MTQzbeKWkRtbMzg7NTsxNzlt4paRG1szODs1OzE3OW3ilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpEbWzM4OzU7MTczbeKWkRtbMzg7NTsxMzRt4paRG1szODs1OzEzNG3ilpEbWzM4OzU7MTM0beKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkRtbMzg7NTsxMzRt4paRG1swbQobWzBtG1swbSAgG1szODs1OzEwOW3ilJQbWzM4OzU7NzRt4paRG1szODs1Ozc0beKWkeKWkeKWkeKWkeKWkeKWkRtbMzg7NTs3NG3ilpEbWzM4OzU7NzRt4paRG1szODs1Ozc0beKWkRtbMzg7NTs3M23ilpEbWzM4OzU7NzNt4paRG1szODs1OzczbeKWkRtbMzg7NTs3M23ilpEbWzM4OzU7Nzlt4paSG1szODs1Ozc4beKWkhtbMzg7NTs3OG3ilpIbWzM4OzU7Nzht4paSG1szODs1OzE0M23ilpEbWzM4OzU7MTc5beKWkRtbMzg7NTsxNzlt4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paRG1szODs1OzE3OW3ilpEbWzM4OzU7MTY3beKWkhtbMzg7NTsxNjdt4paSG1szODs1OzE2N23ilpIbWzM4OzU7MTY4beKWkhtbMzg7NTsxNjht4paSG1szODs1OzE2OG3ilpIbWzM4OzU7MTY4beKWkRtbMzg7NTsxMzNt4paRG1szODs1OzEzM23ilpEbWzM4OzU7MTMzbeKWkRtbMzg7NTsxMzNt4paRG1szODs1OzEzNG3ilpEbWzM4OzU7MTM0beKWkRtbMzg7NTsxMzRt4paRG1szODs1OzEzNG3ilpHilpHilpHilpHilpHilpHilpEbWzBtChtbMG0bWzBtICAgG1szODs1Ozc0beKVmRtbMzg7NTs3NG3ilpEbWzM4OzU7NzRt4paRG1szODs1OzczbeKWkRtbMzg7NTs3OG3ilpIbWzM4OzU7Nzht4paSG1szODs1Ozc4beKWkhtbMzg7NTs3OG3ilpIbWzM4OzU7Nzht4paS4paS4paS4paS4paS4paS4paS4paS4paS4paSG1szODs1OzE0M23ilpEbWzM4OzU7MTc5beKWkRtbMzg7NTsxNzlt4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paRG1szODs1OzE3OW3ilpEbWzM4OzU7MTY3beKWkhtbMzg7NTsxNjdt4paS4paS4paS4paS4paS4paS4paS4paS4paS4paS4paS4paS4paSG1szODs1OzE2N23ilpIbWzM4OzU7MTY4beKWkhtbMzg7NTsxNjht4paSG1szODs1OzEzNG3ilpEbWzM4OzU7MTM0beKWkeKWkRtbMzg7NTsxMzlt4pSAG1swbQobWzBtG1swbSAgICAbWzM4OzU7NzRt4pWaG1szODs1Ozc0beKWkRtbMzg7NTs3NG3ilpEbWzM4OzU7Nzht4paSG1szODs1Ozc4beKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkhtbMzg7NTsxNDNt4paRG1szODs1OzE3OW3ilpEbWzM4OzU7MTc5beKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkRtbMzg7NTsxNzlt4paRG1szODs1OzE2N23ilpIbWzM4OzU7MTY3beKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkhtbMzg7NTsxNjht4paSG1szODs1OzEzNG3ilpEbWzM4OzU7MTM0beKWkRtbMzg7NTsxMzRt4paRG1swbQobWzBtG1swbSAgICAgG1szODs1Ozc0beKWkRtbMzg7NTs3NG3ilpEbWzM4OzU7Nzht4paSG1szODs1Ozc4beKWkhtbMzg7NTs3OG3ilpLilpLilpLilpLilpLilpLilpLilpLilpLilpLilpLilpIbWzM4OzU7MTQzbeKWkRtbMzg7NTsxNzlt4paRG1szODs1OzE3OW3ilpHilpHilpHilpHilpEbWzM4OzU7MTc5bSAbWzM4OzU7MTc5bSAbWzM4OzU7MTQzbSAbWzM4OzU7MTQzbSAbWzM4OzU7MTc5bSAbWzM4OzU7MTc5beKWkhtbMzg7NTsxNzlt4paRG1szODs1OzE3OW3ilpEbWzM4OzU7MTc5beKWkeKWkeKWkeKWkRtbMzg7NTsxNzltIBtbMzg7NTsxNzltIBtbMzg7NTsxNDNtIBtbMzg7NTsxNDNtIBtbMzg7NTsxNDNtIBtbMzg7NTsxNzltIBtbMzg7NTsxNzlt4paRG1szODs1OzE3OW3ilpEbWzM4OzU7MTc5beKWkeKWkeKWkeKWkeKWkRtbMzg7NTsxNzlt4paRG1szODs1OzE2N23ilpIbWzM4OzU7MTY3beKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkhtbMzg7NTsxMzNt4paRG1szODs1OzEzNG3ilpEbWzM4OzU7MTM0beKWkRtbMG0KG1swbRtbMG0gICAgICAbWzM4OzU7NzRt4paRG1szODs1OzczbeKWkhtbMzg7NTs3OG3ilpIbWzM4OzU7Nzht4paS4paS4paS4paS4paS4paS4paS4paS4paS4paS4paS4paSG1szODs1OzE0M23ilpEbWzM4OzU7MTc5beKWkRtbMzg7NTsxNzlt4paR4paR4paR4paRG1szODs1OzE3OW3ilpEbWzM4OzU7MTQzbSAbWzM4OzU7MTQzbSAgICAgG1szODs1OzE3OW3ilpIbWzM4OzU7MTc5beKWkRtbMzg7NTsxNzlt4paR4paR4paR4paRG1szODs1OzE3OW0gG1szODs1OzE0M20gG1szODs1OzE0M20gICAgG1szODs1OzE3OW0gG1szODs1OzE3OW3ilpEbWzM4OzU7MTc5beKWkeKWkeKWkeKWkeKWkRtbMzg7NTsxNzlt4paRG1szODs1OzE2N23ilpIbWzM4OzU7MTY3beKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkhtbMzg7NTsxNjdt4paSG1szODs1OzEzNG3ilpEbWzM4OzU7MTM0beKWkRtbMG0KG1swbRtbMG0gICAgICAbWzM4OzU7MTA5beKUlBtbMzg7NTs3NG3ilpEbWzM4OzU7Nzht4paSG1szODs1Ozc4beKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkhtbMzg7NTsxNDNt4paRG1szODs1OzE3OW3ilpEbWzM4OzU7MTc5beKWkeKWkeKWkeKWkeKWkRtbMzg7NTsxNzlt4pWZG1szODs1OzE3OW0gG1szODs1OzE0M20gG1szODs1OzE0M20gG1szODs1OzE3OW0gG1szODs1OzE3OW0gG1szODs1OzE3OW3ilpEbWzM4OzU7MTc5beKWkRtbMzg7NTsxNzlt4paR4paR4paR4paRG1szODs1OzE3OW3ilpEbWzM4OzU7MTc5bSAbWzM4OzU7MTQzbSAbWzM4OzU7MTQzbSAbWzM4OzU7MTQzbSAbWzM4OzU7MTc5bSAbWzM4OzU7MTc5beKWkRtbMzg7NTsxNzlt4paRG1szODs1OzE3OW3ilpHilpHilpHilpHilpEbWzM4OzU7MTc5beKWkRtbMzg7NTsxNjdt4paSG1szODs1OzE2N23ilpLilpLilpLilpLilpLilpLilpLilpLilpLilpLilpLilpLilpLilpIbWzM4OzU7MTMzbeKWkRtbMzg7NTsxMzRt4paRG1swbQobWzBtG1swbSAgICAgICAbWzM4OzU7NzRt4pWZG1szODs1Ozc4beKWkhtbMzg7NTs3OG3ilpIbWzM4OzU7Nzht4paS4paS4paS4paS4paS4paS4paS4paS4paS4paS4paSG1szODs1OzE0M23ilpEbWzM4OzU7MTc5beKWkRtbMzg7NTsxNzlt4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paRG1szODs1OzE3OW3ilpEbWzM4OzU7MTY3beKWkhtbMzg7NTsxNjdt4paS4paS4paS4paS4paS4paS4paS4paS4paS4paS4paS4paS4paS4paSG1szODs1OzEzNG3ilpEbWzM4OzU7MTM5beKUgBtbMG0KG1swbRtbMG0gICAgICAgIBtbMzg7NTs3M23ilZobWzM4OzU7Nzht4paSG1szODs1Ozc4beKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkhtbMzg7NTsxNDNt4paRG1szODs1OzE3OW3ilpEbWzM4OzU7MTc5beKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkRtbMzg7NTsxNzlt4paRG1szODs1OzE2N23ilpIbWzM4OzU7MTY3beKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkhtbMzg7NTsxNjht4paSG1szODs1OzEzNG3ilpEbWzBtChtbMG0bWzBtICAgICAgICAgG1szODs1Ozc4beKWkhtbMzg7NTs3OG3ilpIbWzM4OzU7Nzht4paS4paS4paS4paS4paS4paS4paS4paS4paS4paSG1szODs1OzE0M23ilpEbWzM4OzU7MTc5beKWkRtbMzg7NTsxNzlt4paR4paR4paR4paR4paR4paR4paR4paRG1szODs1OzE3OW3ilpAbWzM4OzU7MTc5bSAbWzM4OzU7MTc5bSAbWzM4OzU7MTc5bSAbWzM4OzU7MTc5bSAbWzM4OzU7MTc5bSAbWzM4OzU7MTc5bSAgG1szODs1OzE3OW0gG1szODs1OzE3OW0gG1szODs1OzE3OW0gG1szODs1OzE3OW0gG1szODs1OzE3OW3ilpIbWzM4OzU7MTc5beKWkRtbMzg7NTsxNzlt4paR4paR4paR4paR4paR4paR4paR4paRG1szODs1OzE3OW3ilpEbWzM4OzU7MTY3beKWkhtbMzg7NTsxNjdt4paS4paS4paS4paS4paS4paS4paS4paS4paS4paS4paS4paS4paSG1szODs1OzEzM23ilpIbWzBtChtbMG0bWzBtICAgICAgICAgG1szODs1OzEwOG3ilZobWzM4OzU7Nzht4paSG1szODs1Ozc4beKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkhtbMzg7NTsxNDNt4paRG1szODs1OzE3OW3ilpEbWzM4OzU7MTc5beKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkRtbMzg7NTsxNzlt4paRG1szODs1OzE3OW0gG1szODs1OzE0M20gG1szODs1OzE0M20gICAgICAgIBtbMzg7NTsxNDNtIBtbMzg7NTsxNzlt4paRG1szODs1OzE3OW3ilpEbWzM4OzU7MTc5beKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkRtbMzg7NTsxNzlt4paRG1szODs1OzE2N23ilpIbWzM4OzU7MTY3beKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkhtbMzg7NTsxNjdt4paSG1swbQobWzBtG1swbSAgICAgICAgICAbWzM4OzU7Nzht4paSG1szODs1Ozc4beKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkhtbMzg7NTsxNDNt4paRG1szODs1OzE3OW3ilpEbWzM4OzU7MTc5beKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkRtbMzg7NTsxNzlt4paRG1szODs1OzE3OW3ilZobWzM4OzU7MTc5bSAbWzM4OzU7MTQzbSAbWzM4OzU7MTQzbSAgICAbWzM4OzU7MTc5bSAbWzM4OzU7MTc5bSAbWzM4OzU7MTc5beKWkRtbMzg7NTsxNzlt4paRG1szODs1OzE3OW3ilpHilpHilpHilpHilpHilpHilpHilpHilpEbWzM4OzU7MTc5beKWkRtbMzg7NTsxNjdt4paSG1szODs1OzE2N23ilpLilpLilpLilpLilpLilpLilpLilpLilpLilpLilpLilpIbWzM4OzU7MTM4beKWkRtbMG0KG1swbRtbMG0gICAgICAgICAgG1szODs1Ozc4bSAbWzM4OzU7Nzht4paSG1szODs1Ozc4beKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkhtbMzg7NTsxNDNt4paRG1szODs1OzE3OW3ilpEbWzM4OzU7MTc5beKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkRtbMzg7NTsxNzlt4paRG1szODs1OzE3OW0gG1szODs1OzE3OW0gG1szODs1OzE3OW0gG1szODs1OzE3OW3ilpEbWzM4OzU7MTc5beKWkRtbMzg7NTsxNzlt4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paRG1szODs1OzE3OW3ilpEbWzM4OzU7MTY3beKWkhtbMzg7NTsxNjdt4paS4paS4paS4paS4paS4paS4paS4paS4paS4paS4paS4paSG1swbQobWzBtG1swbSAgICAgICAgICAbWzM4OzU7MTA4beKUlBtbMzg7NTs3OG3ilpIbWzM4OzU7Nzht4paS4paS4paS4paS4paS4paS4paS4paS4paSG1szODs1OzE0M23ilpEbWzM4OzU7MTc5beKWkRtbMzg7NTsxNzlt4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paR4paRG1szODs1OzE3OW3ilpEbWzM4OzU7MTY3beKWkhtbMzg7NTsxNjdt4paS4paS4paS4paS4paS4paS4paS4paS4paS4paS4paSG1szODs1OzE2N23ilZkbWzBtChtbMG0bWzBtICAgICAgICAgICAbWzM4OzU7Nzht4paSG1szODs1Ozc4beKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkuKWkhtbMzg7NTs3N23ilpIbWzM4OzU7MTA3beKWkRtbMzg7NTsxMDdt4paRG1szODs1OzEwN23ilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpHilpEbWzM4OzU7MTQzbeKWkhtbMzg7NTsxNDNt4pWaG1szODs1OzE0M20gG1szODs1OzE0M23ilpEbWzM4OzU7MTczbeKWkRtbMzg7NTsxNzNt4paRG1szODs1OzE3M23ilpEbWzM4OzU7MTczbeKWkeKWkeKWkeKWkeKWkeKWkeKWkeKWkRtbMzg7NTsxNzNt4paRG1szODs1OzE3M23ilpIbWzM4OzU7MTY3beKWkhtbMzg7NTsxNjdt4paS4paS4paS4paS4paS4paS4paS4paS4paS4paS4paSG1szODs1OzEzOG3ilIAbWzBtChtbMG0bWzBtICAgICAgICAgICAbWzM4OzU7Nzht4pWaG1szODs1Ozc4beKWkhtbMzg7NTs3OG3ilpLilpLilpLilpLilpLilpLilpLilpLilpLilpLilpIbWzM4OzU7Nzht4paSG1szODs1Ozc4beKVmhtbMzg7NTs3OG3ilZobWzM4OzU7Nzht4pWZG1szODs1OzEwOG3ilZkbWzM4OzU7MTA4beKVmRtbMzg7NTsxMDht4pSUICAgICAgICAgICAgICAgG1szODs1OzEzOG3ilJQbWzM4OzU7MTM4beKUlBtbMzg7NTsxMzht4pWZG1szODs1OzEzOG3ilZkbWzM4OzU7MTY3beKVmhtbMzg7NTsxNjdt4pWaG1szODs1OzE2N23ilZobWzM4OzU7MTY3beKWkhtbMzg7NTsxNjdt4paS4paS4paS4paS4paS4paS4paS4paS4paS4paS4paSG1szODs1OzE2N23ilpIbWzBtChtbMG0bWzBtICAgICAgICAgICAgG1szODs1Ozc4beKVmhtbMzg7NTs3OG3ilZobWzM4OzU7Nzht4pWaG1szODs1Ozc4beKVmRtbMzg7NTsxMDht4pWZG1szODs1OzEwOG3ilJQbWzM4OzU7MTA4beKUlCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIBtbMzg7NTsxMzht4pSUG1szODs1OzEzOG3ilJQbWzM4OzU7MTM4beKVmRtbMzg7NTsxMzht4pWZG1szODs1OzEzMW3ilZobWzM4OzU7MTY3beKVmhtbMzg7NTsxNjdt4pWaG1szODs1OzEzOG3ilJQbWzBtCg==
WENDYEND

  printf '%s' "$_WENDY" | _wendy_decode | while IFS= read -r line; do
    printf '%s%s
' "$indent" "$line"
  done
  printf '[0m
'
}


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────


info() { printf '%s>%s %s\n' "$C_BLUE" "$C_RESET" "$1"; }
ok()   { printf '%s✓%s %s\n' "$C_GREEN" "$C_RESET" "$1"; }
warn() { printf '%s!%s %s\n' "$C_YELLOW" "$C_RESET" "$1" >&2; }
err()  { printf '%s✗%s %s\n' "$C_RED" "$C_RESET" "$1" >&2; }

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    err "Command \`$1\` is required but not found."
    exit 1
  fi
}

ask_password() {
  local prompt="$1"
  local var
  # Prompt and newline go to /dev/tty directly: ask_password is called via
  # command substitution $(...) which captures stdout, so printf to stdout
  # would be swallowed and the user would see no prompt.
  printf '%s' "$prompt" >/dev/tty
  stty -echo
  IFS= read -r var
  stty echo
  printf '\n' >/dev/tty
  echo "$var"
}

hash_password() {
  # SHA256 hex (bash-compatible, no bcrypt needed). Server compares using SHA256.
  local pw="$1"
  if command -v openssl >/dev/null 2>&1; then
    printf '%s' "$pw" | openssl dgst -sha256 | awk '{print $NF}'
  elif command -v shasum >/dev/null 2>&1; then
    printf '%s' "$pw" | shasum -a 256 | awk '{print $1}'
  else
    err "No tool available to hash password (openssl/shasum missing)."
    exit 1
  fi
}

detect_asset() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"
  case "$os" in
    Darwin)
      case "$arch" in
        arm64|aarch64) echo "companion-macos-arm64" ;;
        x86_64) echo "companion-macos-x64" ;;
        *) err "Unsupported macOS architecture: $arch"; exit 1 ;;
      esac
      ;;
    Linux)
      case "$arch" in
        x86_64|amd64) echo "companion-linux-x64" ;;
        *) err "Unsupported Linux architecture: $arch"; exit 1 ;;
      esac
      ;;
    MINGW*|MSYS*|CYGWIN*)
      echo "companion-windows-x64.exe"
      ;;
    *)
      err "Unsupported OS: $os"
      exit 1
      ;;
  esac
}

# ─────────────────────────────────────────────────────────────────────────────
# Cloudflare tunnel helpers
# ─────────────────────────────────────────────────────────────────────────────

CLOUDFLARED_PID=""
CLOUDFLARED_LOG=""
CLOUDFLARED_URL_FILE=""

cleanup_cloudflared() {
  # Restore terminal echo in case the script is killed during password prompt.
  stty echo 2>/dev/null || true
  if [[ -n "$CLOUDFLARED_PID" ]]; then
    kill "$CLOUDFLARED_PID" 2>/dev/null || true
  fi
  if [[ -n "$CLOUDFLARED_LOG" && -f "$CLOUDFLARED_LOG" ]]; then
    rm -f "$CLOUDFLARED_LOG"
  fi
  if [[ -n "$CLOUDFLARED_URL_FILE" && -f "$CLOUDFLARED_URL_FILE" ]]; then
    rm -f "$CLOUDFLARED_URL_FILE"
  fi
}

print_cloudflared_install_hint() {
  local os
  os="$(uname -s)"
  printf '\n%scloudflared is not installed.%s\n' "$C_YELLOW" "$C_RESET"
  case "$os" in
    Darwin)
      printf 'Install on macOS:\n'
      printf '  %sbrew install cloudflare/cloudflare/cloudflared%s\n' "$C_BOLD" "$C_RESET"
      ;;
    Linux)
      printf 'Install on Linux (Debian/Ubuntu):\n'
      printf '  %scurl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb%s\n' "$C_BOLD" "$C_RESET"
      printf '  %ssudo dpkg -i cloudflared.deb%s\n' "$C_BOLD" "$C_RESET"
      printf 'Other distros: see %shttps://github.com/cloudflare/cloudflared/releases/latest%s\n' "$C_BLUE" "$C_RESET"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      printf 'Install on Windows:\n'
      printf '  Download from %shttps://github.com/cloudflare/cloudflared/releases/latest%s\n' "$C_BLUE" "$C_RESET"
      printf '  Or via winget: %swinget install --id Cloudflare.cloudflared%s\n' "$C_BOLD" "$C_RESET"
      ;;
    *)
      printf 'See %shttps://github.com/cloudflare/cloudflared/releases/latest%s\n' "$C_BLUE" "$C_RESET"
      ;;
  esac
  printf '\n'
}

# Launch cloudflared in background and capture the trycloudflare.com URL.
# Writes the URL to CLOUDFLARED_URL_FILE and returns non-zero on timeout.
# Called directly (not via command substitution) so CLOUDFLARED_PID is set
# in the parent shell's scope and the cleanup trap can kill the process.
start_temporary_tunnel() {
  CLOUDFLARED_LOG="${TMPDIR:-/tmp}/cloudflared_$$.log"
  CLOUDFLARED_URL_FILE="${TMPDIR:-/tmp}/cloudflared_url_$$.txt"
  : > "$CLOUDFLARED_LOG"
  : > "$CLOUDFLARED_URL_FILE"

  cloudflared tunnel --url http://localhost:3001 </dev/null >"$CLOUDFLARED_LOG" 2>&1 &
  CLOUDFLARED_PID=$!

  local timeout=30
  local elapsed=0
  local url=""
  local spinner='|/-\'
  local i=0

  while [[ $elapsed -lt $timeout ]]; do
    if ! kill -0 "$CLOUDFLARED_PID" 2>/dev/null; then
      printf '\n'
      warn "cloudflared exited unexpectedly. Last output:"
      tail -n 5 "$CLOUDFLARED_LOG" >&2 || true
      CLOUDFLARED_PID=""
      return 1
    fi

    url="$(grep -Eo 'https://[a-z0-9-]+\.trycloudflare\.com' "$CLOUDFLARED_LOG" 2>/dev/null | head -n1 || true)"
    if [[ -n "$url" ]]; then
      printf '\r%s\r' "$(printf '%*s' 60 '')"
      printf '%s' "$url" > "$CLOUDFLARED_URL_FILE"
      return 0
    fi

    local c="${spinner:$((i % 4)):1}"
    printf '\r%s  %sStarting Cloudflare tunnel… %s%s' "$C_DIM" "$C_RESET" "$c" "$C_RESET"
    i=$((i + 1))
    sleep 1
    elapsed=$((elapsed + 1))
  done

  printf '\r%s\r' "$(printf '%*s' 60 '')"
  return 1
}

# ─────────────────────────────────────────────────────────────────────────────
# Main flow
# ─────────────────────────────────────────────────────────────────────────────

main() {
  require_cmd curl
  require_cmd uname

  trap 'cleanup_cloudflared' EXIT INT TERM

  # When piped via `curl | bash`, stdin is the pipe itself (EOF for reads).
  # Redirect stdin to the terminal so all interactive reads work correctly.
  exec < /dev/tty

  show_wendy

  printf '%sWelcome to Whiteboard Agent.%s\n' "$C_BOLD" "$C_RESET"
  printf 'Wendy will guide you through setting up your local companion.\n\n'

  # ── Cloudflare Tunnel ─────────────────────────────────────────────────────
  printf '%sCloudflare Tunnel%s\n' "$C_BOLD" "$C_RESET"
  printf 'Whiteboard Agent exposes your companion on the internet via Cloudflare Tunnel.\n\n'
  printf '  %s[1]%s Quick start — get a temporary URL now (changes on restart)\n' "$C_BOLD" "$C_RESET"
  printf '  %s[2]%s I already have a permanent URL\n\n' "$C_BOLD" "$C_RESET"

  local tunnel_choice
  while true; do
    printf '%sChoose%s [1/2]: ' "$C_BOLD" "$C_RESET"
    read -r tunnel_choice
    case "$tunnel_choice" in
      1|2) break ;;
      *) warn "Please enter 1 or 2." ;;
    esac
  done

  local companion_url=""

  if [[ "$tunnel_choice" == "1" ]]; then
    if ! command -v cloudflared >/dev/null 2>&1; then
      print_cloudflared_install_hint
      printf '%sPress Enter once cloudflared is installed…%s' "$C_DIM" "$C_RESET"
      read -r _
      if ! command -v cloudflared >/dev/null 2>&1; then
        warn "cloudflared still not found — falling back to manual URL entry."
        tunnel_choice="2"
      fi
    fi
  fi

  if [[ "$tunnel_choice" == "1" ]]; then
    info "Launching temporary Cloudflare tunnel on http://localhost:3001…"
    if start_temporary_tunnel; then
      companion_url="$(cat "$CLOUDFLARED_URL_FILE")"
      rm -f "$CLOUDFLARED_URL_FILE"
      ok "Temporary tunnel ready: $companion_url"
      printf '%sTemporary URL — will change on restart.%s\n' "$C_DIM" "$C_RESET"
      printf 'For a permanent URL, see: %shttps://github.com/palmthree-studio/whiteboard-agent/blob/main/docs/cloudflare-tunnel.md%s\n\n' \
        "$C_BLUE" "$C_RESET"
    else
      warn "Could not capture a trycloudflare.com URL within 30s."
      cleanup_cloudflared
      tunnel_choice="2"
    fi
  fi

  if [[ "$tunnel_choice" == "2" ]]; then
    while true; do
      printf '\n%sYour companion public URL%s (e.g. https://wb.example.com): ' "$C_BOLD" "$C_RESET"
      read -r companion_url
      if [[ "$companion_url" =~ ^https://[a-zA-Z0-9.-]+ ]]; then
        break
      fi
      warn "URL must start with https://"
    done
  fi

  # ── Username ──────────────────────────────────────────────────────────────
  local username
  printf '\n%sOwner username%s: ' "$C_BOLD" "$C_RESET"
  read -r username
  if [[ -z "$username" ]]; then
    err "Username cannot be empty."
    exit 1
  fi

  # ── Password ──────────────────────────────────────────────────────────────
  local pw1 pw2
  while true; do
    pw1="$(ask_password "${C_BOLD}Password${C_RESET}: ")"
    pw2="$(ask_password "${C_BOLD}Confirm password${C_RESET}: ")"
    if [[ "$pw1" == "$pw2" && -n "$pw1" ]]; then
      break
    fi
    warn "Passwords do not match (or empty). Try again."
  done

  local password_hash
  password_hash="$(hash_password "$pw1")"
  unset pw1 pw2

  # ── Asset detection + download ────────────────────────────────────────────
  local asset
  asset="$(detect_asset)"
  info "Detected asset: $asset"

  local install_dir="${WHITEBOARD_INSTALL_DIR:-$HOME/.whiteboard-agent}"
  mkdir -p "$install_dir"

  info "Fetching latest release…"
  local release_json
  release_json="$(curl -fsSL "https://api.github.com/repos/palmthree-studio/whiteboard-agent/releases/latest")"

  local download_url
  if command -v jq >/dev/null 2>&1; then
    download_url="$(printf '%s' "$release_json" | jq -r --arg n "$asset" '.assets[] | select(.name == $n) | .browser_download_url')"
  else
    # Fallback grep/sed without jq
    download_url="$(printf '%s' "$release_json" \
      | tr ',' '\n' \
      | grep -E '"browser_download_url"' \
      | grep -E "/${asset}\"" \
      | head -n1 \
      | sed -E 's/.*"(https:[^"]+)".*/\1/')"
  fi

  if [[ -z "$download_url" ]]; then
    err "Could not find asset $asset in the latest release."
    exit 1
  fi

  local binary_path="$install_dir/companion"
  if [[ "$asset" == *.exe ]]; then
    binary_path="$install_dir/companion.exe"
  fi

  info "Downloading $download_url"
  curl -fsSL "$download_url" -o "$binary_path"
  chmod +x "$binary_path"
  ok "Binary installed: $binary_path"

  # ── Generate whiteboard_agent.md ──────────────────────────────────────────
  local template_url="https://raw.githubusercontent.com/palmthree-studio/whiteboard-agent/main/scripts/whiteboard_agent_template.md"
  local md_path="$install_dir/whiteboard_agent.md"
  info "Generating $md_path"
  local template
  template="$(curl -fsSL "$template_url" 2>/dev/null || true)"
  if [[ -z "$template" ]]; then
    warn "Remote template unavailable — using minimal fallback."
    template="# Whiteboard Agent\n\nServer URL: \$COMPANION_URL/mcp\n"
  fi
  printf '%s\n' "${template//\$COMPANION_URL/$companion_url}" > "$md_path"
  ok "MCP config: $md_path"

  # ── Start companion ───────────────────────────────────────────────────────
  printf '\n%sStarting companion…%s\n' "$C_BOLD" "$C_RESET"
  printf '%sCtrl+C to stop.%s\n\n' "$C_DIM" "$C_RESET"

  printf '%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n' "$C_BOLD" "$C_RESET"
  printf '%s▸ Public URL%s       : %s\n' "$C_BOLD" "$C_RESET" "$companion_url"
  printf '%s▸ Username%s         : %s\n' "$C_BOLD" "$C_RESET" "$username"
  printf '%s▸ MCP config%s       : %s\n' "$C_BOLD" "$C_RESET" "$md_path"
  printf '%s▸ Binary%s           : %s\n' "$C_BOLD" "$C_RESET" "$binary_path"
  printf '%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n\n' "$C_BOLD" "$C_RESET"

  printf '%sWendy: "All set — happy brainstorming!"%s\n\n' "$C_YELLOW" "$C_RESET"

  COMPANION_URL="$companion_url" \
  COMPANION_USERNAME="$username" \
  COMPANION_PASSWORD_HASH="$password_hash" \
  exec "$binary_path"
}

main "$@"

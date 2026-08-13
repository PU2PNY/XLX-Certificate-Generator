#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MODE=check
for a in "$@"; do case "$a" in --check|--dry-run) MODE=check;; --apply) MODE=apply;; -h|--help) echo 'sudo bash update.sh --check|--apply'; exit 0;; *) echo "Unknown option: $a" >&2; exit 2;; esac; done
CFG=/etc/xlx-certificates/module.php
[ -f "$CFG" ] || { echo 'Module config not found; use install.sh first.' >&2; exit 1; }
readarray -t V < <(php -r '$c=require $argv[1]; foreach(["dashboard_dir","site_config","data_dir","secret_file","campaign_pack"] as $k) echo (string)($c[$k]??""),"\n";' "$CFG")
ARGS=("--$MODE" "--dashboard-dir=${V[0]}" "--site-config=${V[1]}" "--data-dir=${V[2]}" "--secret-file=${V[3]}" "--campaign-pack=${V[4]}")
exec bash "$ROOT/install.sh" "${ARGS[@]}"

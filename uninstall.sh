#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
MODE=check; PURGE=no
for a in "$@"; do case "$a" in --check|--dry-run) MODE=check;; --apply) MODE=apply;; --purge-data) PURGE=yes;; *) echo "Unknown option: $a" >&2; exit 2;; esac; done
[ "$(id -u)" -eq 0 ] || { echo 'Execute como root.' >&2; exit 1; }
CFG=/etc/xlx-certificates/module.php
[ -f "$CFG" ] || { echo 'Module config not found.' >&2; exit 1; }
readarray -t V < <(php -r '$c=require $argv[1]; foreach(["dashboard_dir","data_dir","secret_file"] as $k) echo (string)($c[$k]??""),"\n";' "$CFG")
D=${V[0]}; DATA=${V[1]}; SECRET=${V[2]}
if ! grep -Fq 'XLX_CERTIFICATES_OPTIONAL_HOOK_V1' "$D/index.php"; then
  echo '[ERRO] Dashboard sem hook opcional. Remoção automática recusada para não deixar rota hardcoded quebrada.' >&2; exit 1
fi
printf 'Dashboard: %s\nData preserved: %s\nSecret preserved: %s\n' "$D" "$DATA" "$SECRET"
[ "$MODE" = apply ] || { echo STATUS=CERTIFICATES_UNINSTALL_CHECK_OK; exit 0; }
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"; bash "$ROOT/backup.sh" >/dev/null
for rel in certificado-view.php certificado-config.php api/certificado.php assets/certificado.css assets/certificado.js assets/cert-event-alert-v1.css assets/cert-event-alert-v1.js assets/vendor/qrcode.min.js assets/vendor/qrcodejs-LICENSE; do rm -f "$D/$rel"; done
if [ "$PURGE" = yes ]; then rm -rf "$DATA"; rm -f "$SECRET"; fi
rm -f /etc/xlx-certificates/module.php
echo STATUS=CERTIFICATES_UNINSTALL_OK

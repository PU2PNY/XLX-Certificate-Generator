#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
umask 077
[ "$(id -u)" -eq 0 ] || { echo 'Execute como root.' >&2; exit 1; }
CFG=/etc/xlx-certificates/module.php
[ -f "$CFG" ] || { echo 'Module config not found.' >&2; exit 1; }
readarray -t V < <(php -r '$c=require $argv[1]; foreach(["dashboard_dir","data_dir","secret_file"] as $k) echo (string)($c[$k]??""),"\n";' "$CFG")
D=${V[0]}; DATA=${V[1]}; SECRET=${V[2]}; STAMP=$(date +%Y%m%d_%H%M%S); B=/var/backups/xlx-certificates/manual-$STAMP
mkdir -p "$B"; chmod 700 "$B"
LIST="$B/paths.txt"; : > "$LIST"
for p in /etc/xlx-certificates "$DATA" "$SECRET" "$D/certificado-view.php" "$D/certificado-config.php" "$D/api/certificado.php" "$D/assets/certificado.css" "$D/assets/certificado.js" "$D/assets/cert-event-alert-v1.css" "$D/assets/cert-event-alert-v1.js" "$D/assets/vendor/qrcode.min.js" "$D/assets/vendor/qrcodejs-LICENSE"; do [ ! -e "$p" ] || printf '%s\n' "$p" >> "$LIST"; done
tar -czpf "$B/xlx-certificates.tar.gz" -T "$LIST"
sha256sum "$B/xlx-certificates.tar.gz" > "$B/xlx-certificates.tar.gz.sha256"
sha256sum -c "$B/xlx-certificates.tar.gz.sha256" >/dev/null
printf 'BACKUP=%s\nSTATUS=CERTIFICATES_BACKUP_OK\n' "$B/xlx-certificates.tar.gz"

#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
umask 077
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$ROOT/tools/common.sh"

MODE=check; DASHBOARD=""; SITE=""; DATA_DIR=""; SECRET_FILE=""; CAMPAIGN_PACK=auto; NONINTERACTIVE=no
for arg in "$@"; do
  case "$arg" in
    --check|--dry-run) MODE=check ;;
    --apply) MODE=apply ;;
    --dashboard-dir=*) DASHBOARD="${arg#*=}" ;;
    --site-config=*) SITE="${arg#*=}" ;;
    --data-dir=*) DATA_DIR="${arg#*=}" ;;
    --secret-file=*) SECRET_FILE="${arg#*=}" ;;
    --campaign-pack=*) CAMPAIGN_PACK="${arg#*=}" ;;
    --trusted-parent) NONINTERACTIVE=yes ;;
    -h|--help) cat <<'EOF'
XLX Certificate Generator installer
  sudo bash install.sh --check --dashboard-dir=/var/www/html/xlx-dashboard
  sudo bash install.sh --apply --dashboard-dir=/var/www/html/xlx-dashboard
Options: --site-config=FILE --data-dir=DIR --secret-file=FILE --campaign-pack=auto|pt-BR|portable
EOF
      exit 0 ;;
    *) fatal "Opção desconhecida: $arg" ;;
  esac
done

[ "$(id -u)" -eq 0 ] || fatal 'Execute como root.'
for c in bash php rsync sha256sum find openssl tar; do command -v "$c" >/dev/null || fatal "Comando ausente: $c"; done
DASHBOARD="$(cert_detect_dashboard "$DASHBOARD")"
COMPAT="$(cert_validate_dashboard "$DASHBOARD")"
[ -n "$SITE" ] || SITE="$DASHBOARD/config/site.php"
cert_validate_site "$SITE"

# Preserve validated legacy runtime paths without moving data.
REFLECTOR_NAME="$(php -r '$c=require $argv[1]; echo strtoupper(trim((string)$c["reflector"]["name"]));' "$SITE")"
if [ -z "$DATA_DIR" ]; then
  if [ "$REFLECTOR_NAME" = XLX026 ] && [ -d /var/lib/xlx026-certificados ]; then DATA_DIR=/var/lib/xlx026-certificados; else DATA_DIR=/var/lib/xlx-certificates; fi
fi
if [ -z "$SECRET_FILE" ]; then
  if [ "$REFLECTOR_NAME" = XLX026 ] && [ -f /etc/xlx026-certificados/secret ]; then SECRET_FILE=/etc/xlx026-certificados/secret; else SECRET_FILE=/etc/xlx-certificates/secret; fi
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
TMP="/var/tmp/xlx-certificates-${STAMP}"
CAND="$TMP/candidate"
BACK="/var/backups/xlx-certificates/install-${STAMP}"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$CAND/web/api" "$CAND/web/assets/vendor"
rsync -a "$ROOT/web/" "$CAND/web/"
cp "$ROOT/config/certificado-config.php" "$CAND/web/certificado-config.php"
php "$ROOT/tools/render.php" --root="$CAND/web" --site-config="$SITE" --data-dir="$DATA_DIR" --secret-file="$SECRET_FILE" --campaign-pack="$CAMPAIGN_PACK"
while IFS= read -r -d '' f; do php -l "$f" >/dev/null; done < <(find "$CAND/web" -type f -name '*.php' -print0)
if command -v node >/dev/null 2>&1; then while IFS= read -r -d '' f; do node --check "$f" >/dev/null; done < <(find "$CAND/web/assets" -type f -name '*.js' ! -path '*/vendor/*' -print0); fi
if grep -REn '\{\{[A-Z0-9_]+\}\}' "$CAND/web" --exclude='qrcode.min.js' >/dev/null 2>&1; then fatal 'Placeholder não resolvido.'; fi

section 'PLANO'
info "Dashboard: $DASHBOARD"
info "Compatibilidade: $COMPAT"
info "Site config: $SITE"
info "Data dir: $DATA_DIR"
info "Secret file: $SECRET_FILE"
if [ "$MODE" = check ]; then ok 'Candidato validado. Nada foi alterado.'; echo STATUS=CERTIFICATES_CHECK_OK; exit 0; fi

if [ "$NONINTERACTIVE" = yes ]; then
  [ "${XLX_CERTIFICATES_TRUSTED_PARENT:-}" = 1 ] || fatal '--trusted-parent exige XLX_CERTIFICATES_TRUSTED_PARENT=1.'
else
  printf '\nDigite exatamente para instalar:\nCONFIRMO_INSTALACAO_XLX_CERTIFICATES\n\n> '
  read -r typed
  [ "$typed" = CONFIRMO_INSTALACAO_XLX_CERTIFICATES ] || fatal 'Confirmação incorreta.'
fi

mkdir -p "$BACK"; chmod 700 "$BACK"
for rel in certificado-view.php certificado-config.php api/certificado.php assets/certificado.css assets/certificado.js assets/cert-event-alert-v1.css assets/cert-event-alert-v1.js assets/vendor/qrcode.min.js assets/vendor/qrcodejs-LICENSE; do
  [ ! -e "$DASHBOARD/$rel" ] || { mkdir -p "$BACK/$(dirname "$rel")"; cp -a "$DASHBOARD/$rel" "$BACK/$rel"; }
done
sha256sum "$DASHBOARD/index.php" > "$BACK/index.php.sha256"

# Create generic runtime only when not reusing legacy paths.
mkdir -p "$DATA_DIR" "$(dirname "$SECRET_FILE")" /etc/xlx-certificates
chown root:www-data "$DATA_DIR" "$(dirname "$SECRET_FILE")" 2>/dev/null || true
chmod 770 "$DATA_DIR"
for f in "$DATA_DIR/emissoes.jsonl" "$DATA_DIR/rate.json"; do
  if [ ! -e "$f" ]; then [ "${f##*/}" = rate.json ] && printf '{}\n' > "$f" || : > "$f"; fi
  chown root:www-data "$f"; chmod 660 "$f"
done
if [ ! -f "$SECRET_FILE" ]; then
  openssl rand -hex 32 > "$SECRET_FILE"
  chown root:www-data "$SECRET_FILE"; chmod 640 "$SECRET_FILE"
fi

cat > /etc/xlx-certificates/module.php <<EOF
<?php
return [
 'dashboard_dir' => $(printf '%q' "$DASHBOARD" | sed "s/^/'/;s/$/'/"),
 'site_config' => $(printf '%q' "$SITE" | sed "s/^/'/;s/$/'/"),
 'data_dir' => $(printf '%q' "$DATA_DIR" | sed "s/^/'/;s/$/'/"),
 'secret_file' => $(printf '%q' "$SECRET_FILE" | sed "s/^/'/;s/$/'/"),
 'campaign_pack' => $(printf '%q' "$CAMPAIGN_PACK" | sed "s/^/'/;s/$/'/"),
];
EOF
chmod 640 /etc/xlx-certificates/module.php; chown root:www-data /etc/xlx-certificates/module.php

install -D -m 0644 "$CAND/web/certificado-view.php" "$DASHBOARD/certificado-view.php"
install -D -m 0644 "$CAND/web/certificado-config.php" "$DASHBOARD/certificado-config.php"
install -D -m 0644 "$CAND/web/api/certificado.php" "$DASHBOARD/api/certificado.php"
for rel in certificado.css certificado.js cert-event-alert-v1.css cert-event-alert-v1.js; do install -D -m 0644 "$CAND/web/assets/$rel" "$DASHBOARD/assets/$rel"; done
for rel in qrcode.min.js qrcodejs-LICENSE; do install -D -m 0644 "$CAND/web/assets/vendor/$rel" "$DASHBOARD/assets/vendor/$rel"; done
chown root:www-data "$DASHBOARD/certificado-view.php" "$DASHBOARD/certificado-config.php" "$DASHBOARD/api/certificado.php" "$DASHBOARD/assets/certificado.css" "$DASHBOARD/assets/certificado.js" "$DASHBOARD/assets/cert-event-alert-v1.css" "$DASHBOARD/assets/cert-event-alert-v1.js" "$DASHBOARD/assets/vendor/qrcode.min.js" "$DASHBOARD/assets/vendor/qrcodejs-LICENSE"

php -l "$DASHBOARD/api/certificado.php" >/dev/null
php -l "$DASHBOARD/certificado-config.php" >/dev/null
php -r 'require $argv[1]; $c=cert_current_campaign(); if(!is_array($c)||empty($c["title"])) exit(1);' "$DASHBOARD/certificado-config.php"
[ "$(cert_validate_dashboard "$DASHBOARD")" != '' ] || fatal 'Integração deixou de ser reconhecida.'

cat > "$BACK/ROLLBACK.sh" <<EOF
#!/usr/bin/env bash
set -Eeuo pipefail
D='$DASHBOARD'; B='$BACK'
for rel in certificado-view.php certificado-config.php api/certificado.php assets/certificado.css assets/certificado.js assets/cert-event-alert-v1.css assets/cert-event-alert-v1.js assets/vendor/qrcode.min.js assets/vendor/qrcodejs-LICENSE; do
  if [ -e "\$B/\$rel" ]; then mkdir -p "\$D/\$(dirname "\$rel")"; cp -a "\$B/\$rel" "\$D/\$rel"; else rm -f "\$D/\$rel"; fi
done
echo ROLLBACK_OK
EOF
chmod 700 "$BACK/ROLLBACK.sh"
ok 'XLX Certificate Generator instalado sem reiniciar serviços.'
info "Rollback: sudo bash $BACK/ROLLBACK.sh"
echo STATUS=CERTIFICATES_APPLY_OK

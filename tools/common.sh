#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

RED=$'\033[31m'; YELLOW=$'\033[33m'; GREEN=$'\033[32m'; BLUE=$'\033[34m'; RESET=$'\033[0m'
info(){ printf '%s[INFO]%s %s\n' "$BLUE" "$RESET" "$*"; }
ok(){ printf '%s[OK]%s %s\n' "$GREEN" "$RESET" "$*"; }
warn(){ printf '%s[ATENÇÃO]%s %s\n' "$YELLOW" "$RESET" "$*"; }
fatal(){ printf '%s[ERRO]%s %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }
section(){ printf '\n============================================================\n%s\n============================================================\n' "$*"; }

cert_detect_dashboard(){
  local explicit="${1:-}" candidates=() d
  if [ -n "$explicit" ]; then [ -d "$explicit" ] || fatal "Dashboard não encontrado: $explicit"; printf '%s' "$explicit"; return; fi
  for d in /var/www/html/xlx-dashboard /var/www/html/xlxd; do [ -d "$d" ] && candidates+=("$d"); done
  [ "${#candidates[@]}" -eq 1 ] || fatal "Informe --dashboard-dir=DIR para evitar ambiguidade."
  printf '%s' "${candidates[0]}"
}

cert_validate_dashboard(){
  local dash="$1"
  [ -f "$dash/index.php" ] || fatal "index.php ausente: $dash/index.php"
  [ -f "$dash/api/common.php" ] || fatal "Dependência ausente: $dash/api/common.php"
  if grep -Fq 'XLX_CERTIFICATES_OPTIONAL_HOOK_V1' "$dash/index.php"; then echo hook; return; fi
  if grep -Eq "['\"]certificado['\"]" "$dash/index.php" && grep -Fq 'certificado-view.php' "$dash/index.php"; then echo integrated; return; fi
  fatal "Dashboard não possui integração segura de Certificados. Atualize o XLX Modern antes de instalar o módulo."
}

cert_validate_site(){
  local f="$1"
  [ -f "$f" ] || fatal "site config ausente: $f"
  php -l "$f" >/dev/null
  php -r '$c=require $argv[1]; if(!is_array($c)) exit(1); foreach([["reflector","name"],["reflector","title"],["reflector","domain"]] as $p){if(trim((string)($c[$p[0]][$p[1]]??""))==="") exit(2);} new DateTimeZone((string)($c["timezone"]??"UTC"));' "$f" || fatal "site config inválido."
}

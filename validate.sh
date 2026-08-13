#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

for f in "$ROOT"/*.sh; do [ -f "$f" ] && bash -n "$f"; done
while IFS= read -r -d '' f; do php -l "$f" >/dev/null; done < <(find "$ROOT" -type f -name '*.php' -print0)
if command -v node >/dev/null 2>&1; then
  while IFS= read -r -d '' f; do node --check "$f" >/dev/null; done < <(find "$ROOT/web/assets" -type f -name '*.js' ! -path '*/vendor/*' -print0)
fi
if find "$ROOT" -type f \( -name '*.sqlite' -o -name '*.db' -o -name '*.pem' -o -name '*.key' \) -print | grep -q .; then
  echo '[ERRO] runtime/private file found in source tree' >&2; exit 1
fi
if grep -RniE --exclude='qrcode.min.js' --exclude='validate.sh' '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|github_pat_|ghp_[A-Za-z0-9]{20,}' "$ROOT" >/dev/null 2>&1; then
  echo '[ERRO] possible credential found' >&2; exit 1
fi
echo 'STATUS=VALIDATION_OK'

# Security

Nunca publique ou envie para issues/PRs:

- `/etc/xlx-certificates/secret`;
- arquivos sob `/var/lib/xlx-certificates`;
- caminhos legados equivalentes;
- bancos do painel;
- credenciais, cookies, tokens ou chaves privadas.

O segredo HMAC é criado localmente com permissão restrita e não é impresso em logs. O módulo usa `hash_hmac()` e `hash_equals()` para autenticação dos códigos de validação.

O instalador recusa dashboards desconhecidos e valida PHP, placeholders e pré-condições antes de copiar arquivos.

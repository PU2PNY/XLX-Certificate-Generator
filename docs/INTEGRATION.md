# Integração com XLX Modern

O módulo é opcional. O núcleo do painel deve usar o marcador `XLX_CERTIFICATES_OPTIONAL_HOOK_V1` e habilitar a rota apenas quando `certificado-view.php` e `api/certificado.php` estiverem presentes.

Isso evita que o instalador do módulo precise reescrever páginas arbitrárias. Uma instalação antiga que já possua a rota `certificado` também é aceita, preservando sua integração existente.

Dependências fornecidas pelo painel:

- `api/common.php`;
- `parse_xml_connections()`;
- `active_and_history()`;
- `user_lookup()`;
- `country_for_call()`.

O módulo não inclui nem substitui essas funções.

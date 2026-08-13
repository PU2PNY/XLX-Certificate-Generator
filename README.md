# XLX Certificate Generator

Gerador universal e módulo opcional de certificados de participação para o **XLX Modern Dashboard**.

O módulo valida atividade real registrada pelo painel XLX antes da emissão, gera um identificador individual, assina a validação com HMAC e mantém registros locais no servidor. Dados de runtime e segredos **não fazem parte do repositório**.

## Instalação

Pré-validação somente leitura:

```bash
sudo bash install.sh --check --dashboard-dir=/var/www/html/xlx-dashboard
```

Instalação real:

```bash
sudo bash install.sh --apply --dashboard-dir=/var/www/html/xlx-dashboard
```

O instalador usa `config/site.php` do XLX Modern. Em dashboards legados, informe explicitamente `--site-config=/caminho/site.php`.

## Integração

O dashboard é considerado compatível quando:

- possui o hook `XLX_CERTIFICATES_OPTIONAL_HOOK_V1`; ou
- já possui a rota `certificado` integrada.

O instalador **não edita cegamente `index.php`**. Em painel desconhecido ele aborta antes de publicar.

## Runtime

Novas instalações usam por padrão:

- `/etc/xlx-certificates/secret` — chave HMAC, nunca publicada;
- `/etc/xlx-certificates/module.php` — configuração não secreta;
- `/var/lib/xlx-certificates/emissoes.jsonl` — emissões;
- `/var/lib/xlx-certificates/rate.json` — rate limit.

Ao detectar a instalação legada validada do XLX026, o instalador pode reutilizar os caminhos existentes sem copiar ou expor os dados.

## Atualização, backup e remoção

```bash
sudo bash update.sh --check
sudo bash backup.sh
sudo bash uninstall.sh --check
```

A remoção não apaga registros nem a chave HMAC por padrão.

## Segurança

Consulte [SECURITY.md](SECURITY.md).

## Origem

A primeira versão foi extraída de uma instalação XLX em produção e generalizada para uso como módulo independente. QRCode.js mantém sua licença original em `web/assets/vendor/qrcodejs-LICENSE`.

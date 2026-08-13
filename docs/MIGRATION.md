# Migração de instalação legada

O instalador nunca move dados de runtime automaticamente. Se encontrar uma instalação legada compatível, pode reutilizar os caminhos antigos de registros e segredo. Isso permite modularizar o código sem invalidar certificados já emitidos.

A migração física de registros ou troca de segredo deve ser uma operação separada, com backup e validação próprios.

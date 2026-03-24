# Changelog

Todas as mudanças notáveis no projeto **Mangofier** serão documentadas neste arquivo.

## [1.3.0] - 2026-03-23

### Adicionado
- **Wishlist Sync (`bin/mangofier_wishlist_sync`)**: Sincronização da Wish List (lista 1) do MangaUpdates com o banco local. Atualiza metadados de todas as obras da lista em uma única execução.
- **Comando `wishlist` no Analyzer**: `bin/mangofier_analyzer wishlist` para listar obras da Wish List com status de sincronização.

## [1.2.0] - 2026-03-22

### Adicionado
- **Integração Completa com Pessegram v4.0.0**: Mangofier agora opera como bot especializado na arquitetura multi-bot do Pessegram.
- **Bot Mangofier**: Implementação do bot que recebe URLs do MangaUpdates via webhook do Telegram.
- **Processamento Automático**: URLs com "MU:" são automaticamente encaminhadas para mapeamento.
- **Cloudflare Tunnel**: Suporte completo para exposição via túneis Cloudflare.

### Modificado
- **Fluxo de Integração**: Comunicação direta com PessegramService para notificação automática.
- **Configuração**: Variáveis de ambiente atualizadas para integração com Pessegram v4.0.0.

## [1.1.0] - 2026-03-22

### Adicionado
- **Integração com Pessegram**: Ouvinte API (WEBrick) para receber URLs do MangaUpdates via HTTP POST.
- **Processamento de Mensagens com "MU:"**: Respostas do Pessegram que contêm "MU:" são automaticamente encaminhadas para o Mangofier.
- **Comunicação via API**: Cliente HTTP para envio de links mapeados de volta ao Pessegram.
- **Sistema de Notificação**: Feedback automático ao usuário via Pessegram Service.
- **Logs de Debug**: Saída detalhada para monitoramento do fluxo de processamento.

### Modificado
- **Configuração de Ambiente**: Variáveis `LISTENER_PORT`, `LISTENER_API_TOKEN` para API.
- **Fluxo de Processamento**: Agora aceita URLs do MangaUpdates e as converte para IDs do MangaDex.
- **Persistência**: Uso de Model para garantir integridade dos dados.

### Removido
- **Processamento Síncrono**: Substituído por fluxo assíncrono via API.

## [1.0.0] - 2026-03-12

### Adicionado
- **Base do Projeto**: Estrutura Ruby com WEBrick para API.
- **Monitoramento de MangaUpdates**: Checagem periódica de novos capítulos.
- **Banco de Dados SQLite**: Persistência local de obras e progresso.
- **CLI Básica**: Comandos para status e análise.
- **Documentação**: README inicial e este CHANGELOG.
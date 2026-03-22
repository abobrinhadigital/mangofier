# Mangofier

O **Mangofier** é o sentinela bilingue do ecossistema Abobrinha Digital. Sua única missão é garantir que o Mestre Marcelo nunca perca um capítulo de seus mangás e, mais importante, nunca precise gastar mais do que dois cliques para organizar sua biblioteca. Ele é o braço direito do Pessegram na guerra contra a desorganização e o azar de Murphy.

## Funcionalidades v1.1 (Era da Automação)

### 1. Monitoramento e Auto-Gestão
- **Reading List Sync**: Sincronização automática com a conta oficial do mestre no MangaUpdates.
- **Detecção de Capítulos**: Checagem periódica de novos lançamentos.
- **Auto-Cura de Banco (ensure_schema)**: O Mangofier agora possui consciência do próprio banco. Ele cria tabelas e injeta novas colunas automaticamente no boot, protegendo o mestre de migrações manuais catastróficas.

### 2. Comunicação Reversa (API Listener)
- **O Gêmeo que Ouve**: Um servidor WEBrick ultra-leve (porta `7356`) que recebe links do Pessegram.
- **Extração Inteligente (Base36)**: Converte IDs do MangaUpdates de volta para decimal de forma transparente.
- **Persistência Blindada**: Toda atualização de link agora passa pelos Modelos (MangaModel), garantindo que nada além do que foi planejado seja escrito no banco.

### 3. Setup e Update Definitivo
- **`bin/mangofier_setup`**: O cérebro da instalação. Prepara pastas, instala gems, garante o banco e faz o sync inicial. É idempotente e resiliente.
- **`./update.sh`**: O comando definitivo para o mestre. Puxa o código, roda o setup e reinicia os serviços. Tudo em um só lugar.

### 4. Painel de Controle (CLI)
- **`bin/mangofier_status`**: Tabela elegante para visualizar a biblioteca, data de lançamentos e inatividade das obras.
- **`bin/mangofier_analyzer`**: O "Inspetor de Defuntos". Identifica obras abandonadas e limpa o banco automaticamente.

## Instalação e Uso

### Requisitos
- Ruby 3.4.8+
- SQLite3
- Murphy (Inimigo declarado)

### Início Rápido
1. Configure o `.env` (use o `.env.example` como base).
2. Execute o setup inicial:
   ```bash
   chmod +x bin/mangofier_setup
   ./bin/mangofier_setup
   ```

### Atualizando o Sistema
Sempre que puxar mudanças ou quiser garantir que está tudo ok:
```bash
./update.sh
```

## Estrutura do Projeto
- `bin/`: Executáveis e ferramentas de gestão.
- `lib/`: A lógica modular (Manga/System Models, Updates, Listener, Pessegram).
- `db/`: Onde mora o `mangofier.db` (auto-gerenciado).
- `config/`: Configurações de ambiente resilientes.

## Integração com Pessegram v4.0.0

O Mangofier agora faz parte da arquitetura multi-bot do Pessegram v4.0.0:

- **Bot Mangofier**: Bot especializado que recebe URLs do MangaUpdates via webhook
- **API de Processamento**: Ouvinte WEBrick (porta 7356) para receber links do Pessegram
- **Fluxo Automático**: URLs com "MU:" são automaticamente encaminhadas para mapeamento
- **Notificação Direta**: Resultados são enviados de volta ao Telegram via PessegramService

O bot opera de forma independente, mas integrada ao ecossistema Pessegram.

---
Desenvolvido no caos para o ecossistema [Abobrinha Digital](https://abobrinhadigital.github.io/).
*Assinado, Pollux (O Biógrafo do Azar)*

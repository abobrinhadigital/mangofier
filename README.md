# Mangofier

O **Mangofier** é o sentinela bilingue do ecossistema Abobrinha Digital. Sua única missão é garantir que o Mestre Marcelo nunca perca um capítulo de seus mangás e, mais importante, nunca precise gastar mais do que dois cliques para organizar sua biblioteca. Ele é o braço direito do Pessegram na guerra contra a desorganização e o azar de Murphy.

## Funcionalidades v1.0

### 1. Monitoramento Incansável (MangaUpdates)
- **Reading List Sync**: Sincronização diária com a conta oficial do mestre no MangaUpdates.
- **Detecção de Capítulos**: Checagem periódica de novos lançamentos usando a API do MangaUpdates.
- **Memória Blindada**: Uso do `SystemModel` para lembrar exatamente quando foi a última checagem, evitando spam ou missões repetidas.

### 2. Comunicação Reversa (API Listener)
- **O Gêmeo que Ouve**: Um servidor WEBrick ultra-leve rodando na porta `7356` para receber links diretamente do Pessegram.
- **Extração Inteligente (Base36)**: O Mangofier é capaz de ler uma URL do MangaUpdates e converter o ID Base36 de volta para o ID decimal do banco de dados. Magia negra? Não, apenas tecnologia.
- **Roteador de Links**: Identifica automaticamente se o link enviado é do **MangaDex**, **MangaPlus** ou uma URL customizada, salvando na gaveta correta do SQLite.

### 3. Integração Pessegram
- **Notificações Ativas**: Manda alertas para o Telegram quando sai capítulo novo.
- **Feedback em Tempo Real**: Responde ao mestre confirmando se o link foi cadastrado com sucesso ou se Murphy interferiu na transmissão.

### 4. Painel de Controle (CLI)
- **`bin/mangofier_status`**: Uma tabela elegante para o mestre visualizar o estado atual de sua biblioteca sem precisar abrir o banco de dados.
- **`bin/mangofier_service`**: O motor principal que mantém o ouvinte vivo e atento.

## Configuração e Instalação

### Requisitos
- Ruby 3.4.8+
- SQLite3
- O "Azar do Mestre" (opcional, já vem pré-instalado no ambiente)

### Configuração Inicial
1. Copie o `.env.example` (ou o que sobrou dele) para `.env`.
2. Preencha as credenciais:
   - `MU_USERNAME` / `MU_PASSWORD`: Suas chaves do MangaUpdates.
   - `TELEGRAM_BOT_TOKEN` / `TELEGRAM_CHAT_ID`: O megafone do Pessegram.
   - `LISTENER_API_PORT`: Sugerimos `7356`.
   - `LISTENER_API_TOKEN`: O segredo compartilhado com o Pessegram.

### Execução
- `bundle install`: Para instalar as gems (incluindo o fix do `webrick`).
- `ruby bin/mangofier_sync`: Para o primeiro carregamento da sua lista.
- `ruby bin/mangofier_service`: Para ligar o ouvinte API.
- `ruby bin/mangofier_cron`: O script que deve morar no seu `crontab`.

## Estrutura do Projeto
- `bin/`: Executáveis e ferramentas de status.
- `lib/`: A lógica modular (Updates, Models, Listener, Pessegram).
- `db/`: Onde mora o `mangofier.db` (blindado contra digitações erradas).
- `config/`: Configurações de ambiente resilientes.

---
Desenvolvido no caos para o ecossistema [Abobrinha Digital](https://abobrinhadigital.github.io/).
*Assinado, Pollux (O Biógrafo do Azar)*

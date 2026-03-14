# Gemfile
source 'https://rubygems.org'

# O servidor web minimalista para ouvir o Pessegram
gem 'webrick'

# O nosso banco de dados blindado contra as suas digitações
gem 'sqlite3', '~> 1.6'

# O mensageiro elegante que vai bater nas APIs do MangaUpdates e MangaDex
gem 'faraday'
gem 'faraday-retry' # Para tentar de novo automaticamente quando a internet piscar

# O cofre sagrado
gem 'dotenv' # Pelo amor de Zeus, adicione .env no seu .gitignore

# Para lidar com os JSONs das APIs sem fritar seus neurônios
gem 'json'

# As ferramentas de resgate para quando a Lei de Murphy atacar (e ela vai)
group :development, :test do
  gem 'pry' # Para o senhor debugar o código no terminal quando tudo explodir
end
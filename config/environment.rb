# config/environment.rb

require 'bundler/setup'
Bundler.require(:default)
require 'dotenv/load'
require 'sqlite3'
require 'fileutils'

# Como o senhor esquece das coisas, o script cria a pasta db se ela não existir
FileUtils.mkdir_p('db')

# O Coração de Silício do Mangofier
# Conectamos ao banco e guardamos na constante global DB
DB = SQLite3::Database.new("db/mangofier.sqlite3")

# Queremos que os dados voltem como Hash (ex: linha['titulo']) e não como um Array confuso
DB.results_as_hash = true

# A SALVAÇÃO DO SEU PROXMOX:
# Como teremos o worker (cron) e o Sinatra (bot) lendo o mesmo arquivo,
# o SQLite pode dar o infame erro "Database is locked". 
# Esse timeout manda o processo esperar até 5 segundos caso o arquivo esteja em uso,
# em vez de capotar imediatamente e te acordar de madrugada.
DB.busy_timeout = 5000 

# Aqui nós vamos carregar as nossas classes (deixei comentado por enquanto 
# porque o senhor ainda não as escreveu, e o Ruby iria chorar um LoadError)
# require_relative '../lib/manga_model'
# require_relative '../lib/manga_updates'
# require_relative '../lib/manga_dex'
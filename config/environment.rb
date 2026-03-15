# config/environment.rb
require 'bundler/setup'
Bundler.require(:default)
require 'dotenv/load'
require 'sqlite3'
require 'fileutils'

# Caminhos Absolutos para não ter erro no Proxmox/Servidor
APP_ROOT = File.expand_path('..', __dir__)
DB_DIR  = File.join(APP_ROOT, 'db')
DB_PATH = File.join(DB_DIR, 'mangofier.db')

FileUtils.mkdir_p(DB_DIR)

# O Coração de Silício Centralizado
# Conectamos ao banco e guardamos na constante global DB
DB = SQLite3::Database.new(DB_PATH)

# Configurações Globais de Resiliência
DB.results_as_hash = true
DB.busy_timeout = 5000 
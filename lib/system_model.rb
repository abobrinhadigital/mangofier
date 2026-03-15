# lib/system_model.rb

class SystemModel
  def self.db
    DB.tap do |db|
      db.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS sistema (
          chave TEXT PRIMARY KEY,
          valor TEXT
        );
      SQL

      db.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS mangas_mapeados (
          mu_id INTEGER PRIMARY KEY,
          titulo TEXT,
          md_id TEXT,
          mp_url TEXT,
          custom_url TEXT,
          last_release_at INTEGER
        );
      SQL
    end
  end

  def self.get_last_check
    row = DB.execute("SELECT valor FROM sistema WHERE chave = 'last_check' LIMIT 1").first
    
    if row
      return row['valor'].to_i
    else
      # A LÓGICA DO MESTRE ENCAPSULADA:
      # Se for a primeira vez (não existe no banco), corta para hoje à meia-noite!
      hoje_meia_noite = Date.today.to_time.to_i
      set_last_check(hoje_meia_noite)
      
      puts "⚠️ [SystemModel] Primeira execução detetada! Relógio ajustado internamente para hoje às 00:00 (Timestamp: #{hoje_meia_noite})."
      return hoje_meia_noite
    end
  end

  def self.set_last_check(timestamp)
    DB.execute("INSERT OR REPLACE INTO sistema (chave, valor) VALUES ('last_check', ?)", [timestamp.to_s])
  end
end
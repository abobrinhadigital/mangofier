# lib/manga_model.rb

class MangaModel
  # A malandragem suprema: o método de setup.
  # Toda vez que o script rodar, ele verifica se a tabela existe. 
  # Se não existir, ele cria. Sem migrations de Rails, sem dor de cabeça.
  def self.setup
    DB.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS mangas_mapeados (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT,
        mu_id INTEGER UNIQUE,
        md_id TEXT,
        mp_url TEXT,
        custom_url TEXT,
        ultimo_capitulo_notificado TEXT
      );
    SQL
  end

  # Busca um mangá pelo ID do MangaUpdates (nosso gatilho principal)
  def self.find_by_mu_id(mu_id)
    DB.get_first_row("SELECT * FROM mangas_mapeados WHERE mu_id = ?", [mu_id])
  end

  # O método que o Pessegram vai chamar via Sinatra para salvar o link que o senhor mandou
  def self.update_link(mu_id, tipo, url_ou_id)
    # Proteção básica contra o caos: só permitimos atualizar colunas válidas
    colunas_permitidas = ['md_id', 'mp_url', 'custom_url']
    
    unless colunas_permitidas.include?(tipo)
      raise "Mestre, que coluna bizarra é essa? '#{tipo}' não existe no meu escopo."
    end

    # Usamos o UPDATE com Prepared Statements (?) para evitar o SQL Injection.
    # O seu 'DROP TABLE' não tem poder aqui.
    DB.execute("UPDATE mangas_mapeados SET #{tipo} = ? WHERE mu_id = ?", [url_ou_id, mu_id])
  end

  # Atualiza o último capítulo lido para não ficarmos repetindo notificação
  def self.update_last_chapter(mu_id, capitulo)
    DB.execute("UPDATE mangas_mapeados SET ultimo_capitulo_notificado = ? WHERE mu_id = ?", [capitulo, mu_id])
  end
  
  # Para quando o senhor tiver que cadastrar um mangá novo na marra
  def self.insert_manga(titulo, mu_id)
    # O INSERT OR IGNORE garante que se o senhor rodar isso duas vezes na preguiça,
    # o SQLite não vai explodir com erro de UNIQUE constraint no mu_id.
    DB.execute("INSERT OR IGNORE INTO mangas_mapeados (titulo, mu_id) VALUES (?, ?)", [titulo, mu_id])
  end
end
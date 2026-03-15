# lib/manga_model.rb

class MangaModel
  def self.ensure_schema
    DB.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS mangas_mapeados (
        mu_id INTEGER PRIMARY KEY,
        titulo TEXT,
        ultimo_capitulo_notificado TEXT,
        md_id TEXT,
        mp_url TEXT,
        custom_url TEXT,
        last_release_at INTEGER
      );
    SQL

    # Auto-identidade do Pollux: Garante que colunas novas existam em bases antigas
    columns = DB.execute("PRAGMA table_info(mangas_mapeados)").map { |c| c['name'] }
    
    unless columns.include?('last_release_at')
      puts "➕ [MangaModel] Adicionando coluna 'last_release_at'..."
      DB.execute("ALTER TABLE mangas_mapeados ADD COLUMN last_release_at INTEGER")
    end
  end

  def self.insert_manga(titulo, mu_id)
    DB.execute("INSERT OR IGNORE INTO mangas_mapeados (mu_id, titulo) VALUES (?, ?)", [mu_id, titulo])
  end

  def self.find_by_mu_id(mu_id)
    DB.execute("SELECT * FROM mangas_mapeados WHERE mu_id = ? LIMIT 1", [mu_id]).first
  end

  def self.update_last_chapter(mu_id, capitulo)
    DB.execute("UPDATE mangas_mapeados SET ultimo_capitulo_notificado = ? WHERE mu_id = ?", [capitulo.to_s, mu_id])
  end

  def self.get_all_mu_ids
    DB.execute("SELECT mu_id FROM mangas_mapeados").map { |row| row['mu_id'] }
  end

  def self.delete_by_mu_id(mu_id)
    DB.execute("DELETE FROM mangas_mapeados WHERE mu_id = ?", [mu_id])
  end

  # Retorna todos os mangás com seus links e datas para análise (Centralização Pollux 🏛️)
  def self.all_for_analysis
    DB.execute("SELECT mu_id, titulo, last_release_at, mp_url, md_id, custom_url FROM mangas_mapeados ORDER BY titulo ASC")
  end

  # Atualiza a data do último lançamento real detectado
  def self.update_last_release(mu_id, timestamp)
    DB.execute("UPDATE mangas_mapeados SET last_release_at = ? WHERE mu_id = ?", [timestamp, mu_id])
  end

  # Atualiza links de leitura (Centralização Pollux 🎧)
  def self.update_link(mu_id, coluna, valor)
    # Lista de colunas permitidas para evitar injeção (mesmo vindo de nós)
    colunas_validas = ['md_id', 'mp_url', 'custom_url']
    raise "Coluna inválida: #{coluna}" unless colunas_validas.include?(coluna)

    DB.execute("UPDATE mangas_mapeados SET #{coluna} = ? WHERE mu_id = ?", [valor, mu_id])
  end
end
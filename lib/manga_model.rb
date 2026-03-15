# lib/manga_model.rb
require 'sqlite3'

class MangaModel
  def self.db
    DB.tap do |db|
      db.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS mangas_mapeados (
          mu_id INTEGER PRIMARY KEY,
          titulo TEXT,
          ultimo_capitulo_notificado TEXT,
          md_id TEXT,
          mp_url TEXT,
          custom_url TEXT
        );
      SQL
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
end
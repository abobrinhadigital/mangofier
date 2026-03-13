# lib/manga_dex.rb
require 'faraday'
require 'json'

class MangaDex
  BASE_URL = 'https://api.mangadex.org'

  def initialize
    # O MangaDex é uma mãe: não precisa de autenticação para buscar capítulos!
    # Configuramos o Faraday para ser resiliente e já cuspir o corpo em JSON
    @conn = Faraday.new(url: BASE_URL) do |f|
      f.request :json
      f.response :json, parser_options: { symbolize_names: true }
      f.adapter Faraday.default_adapter
    end
  end

  # Busca o ID da obra no MangaDex pelo título (caso a gente ainda não tenha no SQLite)
  def search_manga(title)
    puts "MangaDex: Procurando a obra '#{title}'..."
    
    response = @conn.get('manga') do |req|
      req.params['title'] = title
      req.params['limit'] = 1 # O senhor é preguiçoso, vamos pegar só o primeiro resultado e torcer
      req.params['order[relevance]'] = 'desc'
    end

    if response.status == 200 && !response.body[:data].empty?
      manga = response.body[:data].first
      puts "Encontrado! O ID no MangaDex é #{manga[:id]}."
      return manga[:id]
    else
      puts "MangaDex: Não achei nada com o nome '#{title}'. Vai ler no custom_url mesmo."
      return nil
    end
  end

  # A Joia da Coroa: Pega o ID da obra e cospe o link do último capítulo
  def get_latest_chapter_link(md_id, language = 'pt-br')
    puts "MangaDex: Buscando o último capítulo lançado para o ID #{md_id}..."

    response = @conn.get("manga/#{md_id}/feed") do |req|
      req.params['translatedLanguage[]'] = language
      req.params['limit'] = 1
      req.params['order[chapter]'] = 'desc' # Ordena do mais recente pro mais antigo
    end

    if response.status == 200 && !response.body[:data].empty?
      chapter = response.body[:data].first
      chapter_id = chapter[:id]
      chapter_num = chapter[:attributes][:chapter]
      
      puts "Capítulo #{chapter_num} encontrado!"
      
      # Retornamos um Hash bonitinho com o número para o SQLite e o link mastigado para o Pessegram
      return {
        number: chapter_num,
        url: "https://mangadex.org/chapter/#{chapter_id}"
      }
    else
      puts "MangaDex: Nenhum capítulo encontrado em #{language}. Os tradutores estão de greve."
      return nil
    end
  end
end
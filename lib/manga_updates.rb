# lib/manga_updates.rb
require 'faraday'
require 'json'

class MangaUpdates
  BASE_URL = 'https://api.mangaupdates.com/v1'

  def initialize
    @username = ENV['MU_USERNAME']
    @password = ENV['MU_PASSWORD']
    @token = nil

    @conn = Faraday.new(url: BASE_URL) do |f|
      f.request :json
      f.response :json, parser_options: { symbolize_names: true }
      f.adapter Faraday.default_adapter
    end
  end

  def login
    puts "🚪 Batendo na porta do MangaUpdates como #{@username}..."
    response = @conn.put('account/login') do |req|
      req.body = { username: @username, password: @password }
    end

    if response.status == 200 && response.body[:context]
      @token = response.body[:context][:session_token]
      puts "✅ Login efetuado. A chave da gaveta está no bolso."
    else
      raise "🚨 Falha no login! Status: #{response.status}. Mestre, verifique a senha no .env."
    end
  end

  # O Chute 2 (Vitorioso): Busca a lista 0 filtrando via POST e cria o Dicionário
  def fetch_reading_list
    login if @token.nil?

    puts "📂 Puxando as obras da gaveta 0 (Reading List)..."
    response = @conn.post('series/search') do |req|
      req.headers['Authorization'] = "Bearer #{@token}"
      req.body = { list_id: 0 }
    end

    if response.status == 200 && response.body[:results]
      obras = response.body[:results]
      
      # A MÁGICA: Criando o Dicionário { "Nome" => ID }
      mapa = {}
      obras.each do |item|
        id = item.dig(:record, :series_id) || item.dig(:record, :id)
        titulo = item.dig(:record, :title)
        mapa[titulo] = id if titulo && id
      end
      
      puts "✅ Achamos #{mapa.length} mangás na sua lista."
      return mapa
    else
      raise "🚨 O MangaUpdates trancou a gaveta! Status: #{response.status}"
    end
  end

  # A Economia Máxima: Manda o pacotão de IDs de uma vez só
  def check_batch_releases(lista_de_ids)
    return [] if lista_de_ids.empty?

    puts "📡 Checando fofocas recentes para #{lista_de_ids.length} obras num único ping..."
    response = @conn.post("releases/search") do |req|
      req.body = { series_id: lista_de_ids }
    end

    if response.status == 200 && response.body[:results]
      return response.body[:results]
    else
      puts "⚠️ MangaUpdates negou o pacote de lançamentos. Status: #{response.status}"
      return []
    end
  end
end
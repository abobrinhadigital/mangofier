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
    puts "🚪 A bater na porta do MangaUpdates como #{@username}..."
    response = @conn.put('account/login') do |req|
      req.body = { username: @username, password: @password }
    end

    if response.status == 200 && response.body[:context]
      @token = response.body[:context][:session_token]
      puts "✅ Login efetuado."
    else
      raise "🚨 Falha no login! Status: #{response.status}."
    end
  end

  def fetch_reading_list
    login if @token.nil?
    puts "📂 A puxar as obras da gaveta 0 (Endpoint Direto)..."

    response = @conn.post('lists/0/search') do |req|
      req.headers['Authorization'] = "Bearer #{@token}"
      req.body = {} 
    end

    if response.status == 200 && response.body[:results]
      obras = response.body[:results]
      mapa = {}

      obras.each do |item|
        id = item.dig(:record, :series, :id)
        titulo = item.dig(:record, :series, :title)
        mapa[titulo] = id if titulo && id
      end

      return mapa
    else
      raise "🚨 O MangaUpdates trancou a gaveta! Status: #{response.status}"
    end
  end

# A NOVA BUSCA POR TEMPO (Corrigida e com Visão de Raio-X)
  def check_new_releases(last_check_timestamp)
    # Transforma o nosso timestamp num formato "YYYY-MM-DD" para o start_date
    data_inicio_str = Time.at(last_check_timestamp).strftime('%Y-%m-%d')
    
    puts "📡 A procurar lançamentos novos desde o timestamp #{last_check_timestamp} (Data: #{data_inicio_str})..."
    
    page = 1
    lancamentos_validos = []
    maior_timestamp = last_check_timestamp

    loop do
      response = @conn.post("releases/search") do |req|
        req.body = {
          page: page,
          per_page: 100,
          orderby: "date",
          start_date: data_inicio_str, # <-- A peça de ouro do seu Postman!
          asc: "desc",
          include_metadata: true 
        }
      end

      if response.status == 200 && response.body[:results]
        obras = response.body[:results]
        break if obras.empty?

        # O NOSSO ESPIÃO: Imprime o primeiro item da página para vermos o que a API está a fazer
        primeira_fofoca = obras.first
        data_primeira_fofoca = primeira_fofoca.dig(:record, :time_added, :as_string)
        puts "👁️ [Debug] Página #{page} iniciada. Primeira fofoca vinda da API: #{data_primeira_fofoca}"

        barreira_do_tempo_atingida = false

        obras.each do |item|
          fofoca_ts = item.dig(:record, :time_added, :timestamp).to_i
          
          if fofoca_ts <= last_check_timestamp
            barreira_do_tempo_atingida = true
            break 
          end
          
          maior_timestamp = fofoca_ts if fofoca_ts > maior_timestamp
          
          mu_id = item.dig(:metadata, :series, :series_id)
          titulo = item.dig(:metadata, :series, :title)
          capitulo = item.dig(:record, :chapter)

          if mu_id && capitulo
            lancamentos_validos << {
              mu_id: mu_id,
              titulo: titulo,
              capitulo: capitulo,
              timestamp: fofoca_ts
            }
          end
        end

        break if barreira_do_tempo_atingida
        break if obras.length < 100
        
        page += 1
      else
        puts "⚠️ MangaUpdates negou o feed. Status: #{response.status}"
        break
      end
    end
    
    return lancamentos_validos, maior_timestamp
  end
end
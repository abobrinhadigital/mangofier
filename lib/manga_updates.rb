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

  # Versão turbinada que traz os metadados (last_updated) de toda a lista de uma vez de forma atômica
  def fetch_reading_list_with_metadata
    login if @token.nil?
    
    response = @conn.post('lists/0/search') do |req|
      req.headers['Authorization'] = "Bearer #{@token}"
      req.body = {} # Sem paginação = Lista completa (Truque do Mestre)
    end

    if response.status == 200 && response.body[:results]
      return response.body[:results].map do |item|
        {
          mu_id: item.dig(:record, :series, :id),
          titulo: item.dig(:record, :series, :title),
          last_updated: item.dig(:metadata, :series, :last_updated, :timestamp)
        }
      end
    end
    
    []
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

  # Busca metadados precisos da série usando o endpoint de groups (Sugestão do MESTRE 🏆)
  # Este endpoint é o único que separa os lançamentos reais da obra da "fofoca global" da API.
  # @param series_title [String] Título da série para busca textual (fallback)
  # @param mu_id_longo [Integer] ID de 11 dígitos da obra (se já conhecido)
  def fetch_series_last_release_date(series_title, mu_id_longo = nil)
    login if @token.nil?
    
    # Se já temos o ID longo (vários dígitos), pulamos a busca textual. O mestre gosta de atalhos!
    unless mu_id_longo && mu_id_longo.to_s.length > 8
      # PASSO 1: Descobrir o ID LONGO de 11 dígitos (A API v1 ignora IDs curtos em muitos filtros)
      search_resp = @conn.post("series/search") do |req|
        req.body = { search: series_title, per_page: 5 }
      end

      if search_resp.status == 200 && search_resp.body[:results]
        # Match por título exato para evitar falsos positivos
        match = search_resp.body[:results].find do |r|
          mu_titulo = r.dig(:record, :title)
          mu_titulo && mu_titulo.downcase.strip == series_title.downcase.strip
        end
        
        # Se não achar match exato, tentamos o primeiro (melhor que nada)
        match ||= search_resp.body[:results].first
        mu_id_longo = match.dig(:record, :series_id) if match
      end
    end

    if mu_id_longo
      # PASSO 2: Consultar o endpoint de GROUPS sugerido pelo mestre para pegar a release_list real
      groups_resp = @conn.get("series/#{mu_id_longo}/groups") do |req|
        req.headers['Authorization'] = "Bearer #{@token}"
      end

      if groups_resp.status == 200 && groups_resp.body[:release_list]
        # Pega o primeiro (mais recente) da lista de lançamentos da obra
        top = groups_resp.body[:release_list].first
        return top.dig(:time_added, :timestamp).to_i if top
      end
    end
    
    nil # Não encontrado ou sem data real
  end

  # Busca detalhes completos de uma série (incluindo o last_updated.timestamp sugerido pelo mestre)
  def fetch_series_details(mu_id)
    login if @token.nil?
    
    response = @conn.get("series/#{mu_id}") do |req|
      req.headers['Authorization'] = "Bearer #{@token}"
    end

    if response.status == 200
      return response.body
    end
    
    nil
  end

  # Adiciona uma série a uma lista específica (ex: 106 para Abandoned)
  def add_to_list(mu_id, list_id)
    login if @token.nil?
    
    # Se a obra já estiver em qualquer lista, o POST falha.
    # Como não sabemos em qual lista ela está sem buscar tudo, 
    # a estratégia mais segura (e recomendada pelo teste 8) é tentar remover 
    # de qualquer lista potencial ou simplesmente remover da Reading (0) antes.
    remove_from_list(mu_id, 0) 
    
    response = @conn.post("lists/series") do |req|
      req.headers['Authorization'] = "Bearer #{@token}"
      req.body = [{ series: { id: mu_id }, list_id: list_id }]
    end

    response.status == 200
  end

  # Remove uma série de uma lista específica (ex: 0 para Reading)
  # O MangaUpdates v1 usa POST para delete em listas! (Descoberta do Teste 8 🕵️)
  def remove_from_list(mu_id, list_id)
    login if @token.nil?
    
    response = @conn.post("lists/series/delete") do |req|
      req.headers['Authorization'] = "Bearer #{@token}"
      req.body = [mu_id] # Array simples de IDs
    end

    response.status == 200
  end

  # Move várias séries de uma vez para uma nova lista (O Atropelamento Atômico 🏛️)
  def bulk_move_to_list(collection, list_id)
    login if @token.nil?
    
    # Monta o payload conforme a documentação enviada pelo Mestre
    payload = collection.map do |m|
      mu_id = m[:mu_id] || m['mu_id']
      {
        series: { id: mu_id },
        list_id: list_id
      }
    end

    puts "📡 Enviando lote de #{payload.length} obras para a Lista #{list_id}..."
    
    response = @conn.post("lists/series/update") do |req|
      req.headers['Authorization'] = "Bearer #{@token}"
      req.body = payload
    end

    if response.status == 200
      puts "✅ Lote processado com sucesso pelo MangaUpdates."
      return true
    else
      puts "🚨 Falha no Bulk Update. Status: #{response.status}"
      return false
    end
  end

  # criar novo método para buscar a página do grupo
  def fetch_group_site(mu_id)
    login if @token.nil?
    
    # aqui embaixo tem de ir a lógica parecida com o probe_mu_groups.rb
    response = @conn.get("series/#{mu_id}/groups") do |req|
      req.headers['Authorization'] = "Bearer #{@token}"
    end
    if response.status == 200
      groups_data = response.body
      
      # Focar no group_list se existir
      if groups_data[:release_list]
        # 1. Primeiro pegamos o ID do grupo lá no topo da release_list
        meu_group_id = groups_data[:release_list][0][:groups][0][:group_id]
        # 2. Agora procuramos o grupo que bate com esse ID dentro da group_list
        grupo_vencedor = groups_data[:group_list].find { |g| g[:group_id] == meu_group_id }
        # 3. Agora o senhor tem o pote de ouro!
        pagina_grupo = grupo_vencedor[:social][:website][0] if grupo_vencedor
      else
        # devolver que não foi encontrado grupo, pro bin/mangofier_cron avisar que não tem o grupo
        pagina_grupo = nil
      end
    else
      pagina_grupo = nil
    end
  end

end
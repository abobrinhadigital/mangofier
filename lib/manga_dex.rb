# lib/manga_dex.rb
require 'faraday'
require 'json'

class MangaDex
  BASE_URL = 'https://api.mangadex.org'

  def initialize
    @conn = Faraday.new(url: BASE_URL) do |f|
      f.request :json
      f.response :json, parser_options: { symbolize_names: true }
      f.adapter Faraday.default_adapter
    end
  end

  # Consulta básica por título (O primeiro contato 🏮)
  def search_manga(title)
    puts "🏮 A sondar os arquivos da MangaDex por: '#{title}'..."
    
    response = @conn.get('manga') do |req|
      req.params['title'] = title
      req.params['limit'] = 5
    end

    if response.status == 200
      return response.body
    else
      puts "🚨 MangaDex recusou a sonda. Status: #{response.status}"
      return nil
    end
  end

  # Consulta página do mangá pelo título
  def get_manga_id(title)
    response = @conn.get('manga') do |req|
      req.params['title'] = title
      req.params['limit'] = 5
    end

    if response.status == 200 && response.body[:data] && !response.body[:data].empty?
      return response.body[:data][0][:id]
    else
      return nil
    end
  end

end

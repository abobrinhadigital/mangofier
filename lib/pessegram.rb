# lib/pessegram.rb
require 'faraday'
require 'json'

class Pessegram
  def initialize
    @api_url = ENV['PESSEGRAM_API_URL']
    @token = ENV['PESSEGRAM_API_TOKEN']
    @chat_id = ENV['PESSEGRAM_CHAT_ID']

    # MODO DE TESTE LOCAL:
    # Mude para 'false' quando for mandar isso de volta pro Abobrinator!
    @mutado = false
  end

  def gritar(mensagem)
    # Se estiver mutado, apenas imprime na tela com elegância
    if @mutado
      puts "\n🔕 [PESSEGRAM MUDO - TESTE LOCAL]:\n#{mensagem}\n"
      return
    end

    unless @api_url && @token
      puts '🚨 Erro: O Pessegram não achou a URL ou o TOKEN da API no .env!'
      return
    end

    # Envia via novo endpoint /bot/mangofier
    begin
      url = "#{@api_url}/bot/mangofier"
      response = Faraday.post(url) do |req|
        req.body = { mensagem: mensagem, chat_id: @chat_id }.to_json
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{@token}"
      end

      puts "🚨 [Pessegram] Erro na API: Status #{response.status}" if response.status != 200
    rescue StandardError => e
      puts "🚨 Falha ao gritar na API do Pessegram: #{e.message}"
    end
  end
end

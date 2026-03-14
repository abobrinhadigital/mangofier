# lib/pessegram.rb
require 'faraday'
require 'json'

class Pessegram
  def initialize
    @api_url = ENV['PESSEGRAM_API_URL']
    @token = ENV['PESSEGRAM_API_TOKEN']
    
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
      puts "🚨 Erro: O Pessegram não achou a URL ou o TOKEN da API no .env!"
      return
    end

    # Agora o Carteiro faz a entrega diretamente ao Mestre via a API do Pessegram!
    begin
      response = Faraday.post(@api_url) do |req|
        req.body = { mensagem: mensagem }.to_json
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{@token}"
      end
      
      if response.status != 200
        puts "🚨 [Pessegram] Erro na API: Status #{response.status}"
      end
    rescue => e
      puts "🚨 Falha ao gritar na API do Pessegram: #{e.message}"
    end
  end
end
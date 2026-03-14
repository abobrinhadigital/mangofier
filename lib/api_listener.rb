# lib/api_listener.rb
require 'webrick'
require 'json'
require_relative 'manga_model'
require_relative 'pessegram'

module Mangofier
  class ApiListener
    def self.start
      port = (ENV['LISTENER_API_PORT'] || 7356).to_i
      token = ENV['LISTENER_API_TOKEN']

      server = WEBrick::HTTPServer.new(
        Port: port,
        BindAddress: '0.0.0.0',
        # Agora vamos de fato ver os logs no console!
        Logger: WEBrick::Log.new($stdout),
        AccessLog: [[$stdout, WEBrick::AccessLog::COMBINED_LOG_FORMAT]]
      )

      # O endpoint universal que recebe o JSON do Pessegram (formato: mensagem e contexto)
      server.mount_proc '/cadastrarlink' do |req, res|
        auth_header = req['authorization'] || req['Authorization']

        if req.request_method == 'POST' && auth_header == "Bearer #{token}"
          begin
            payload = JSON.parse(req.body)
            puts "📥 [DEBUG] Payload recebido: #{payload.inspect}"
            
            # O Pessegram manda: { "mensagem" => "url", "contexto" => "texto da msg original" }
            raw_url = payload['mensagem']
            contexto_texto = payload['contexto'].to_s
            
            unless raw_url && !contexto_texto.empty?
              res.status = 400
              res.body = { erro: 'Mestre, dados incompletos. Preciso da URL e do contexto da mensagem.' }.to_json
              next
            end

            # 1. Extração do mu_id (O "Pulo do Gato" Base36)
            # O Pessegram manda o texto da mensagem original no 'contexto'
            mu_match = contexto_texto.match(/mangaupdates\.com\/series\/([a-z0-9]+)/i)
            
            unless mu_match
              res.status = 422
              res.body = { erro: 'Não achei a URL do MangaUpdates no contexto. Murphy atacou!' }.to_json
              next
            end

            # Converte de Base36 para Decimal
            mu_id_dec = mu_match[1].to_i(36)
            
            # 2. Extração e Roteamento do Link
            # O link que o mestre mandou está no campo 'mensagem'
            url_final = raw_url.to_s.strip
            
            if url_final.empty?
              res.status = 400
              res.body = { erro: 'O link que o senhor mandou está vazio!' }.to_json
              next
            end

            coluna, valor_final = rotear_link(url_final)

            # 3. Persistência no SQLite
            # Primeiro buscamos o título para dar um feedback bonito
            manga = MangaModel.find_by_mu_id(mu_id_dec)
            titulo = manga ? manga['titulo'] : "Mangá ID #{mu_id_dec}"

            MangaModel.db.execute(
              "UPDATE mangas_mapeados SET #{coluna} = ? WHERE mu_id = ?",
              [valor_final, mu_id_dec]
            )
            
            # 4. Feedback para o Mestre via Telegram
            pessegram = Pessegram.new
            pessegram.gritar("✅ *Mangofier:* Link cadastrado com sucesso para \"#{titulo}\"!\n📍 Coluna: #{coluna}")

            res.status = 200
            res.body = { status: 'sucesso', mu_id: mu_id_dec, coluna: coluna }.to_json
            puts "✅ Link atualizado via API: MU_ID #{mu_id_dec} -> #{coluna}"

          rescue => e
            Pessegram.new.gritar("🚨 *Mangofier:* Erro ao processar seu link: #{e.message}")
            res.status = 500
            res.body = { erro: "O Mangofier engasgou: #{e.message}" }.to_json
          end
        else
          res.status = 401
          res.body = { erro: 'Acesso negado. Mostre o token ou dê meia-volta.' }.to_json
        end
      end

      Thread.new do
        puts "🎧 Mangofier Listener (o Gêmeo Silencioso) aguardando na porta #{port}..."
        server.start
      end
    end

    private

    def self.rotear_link(url)
      if url.include?('mangadex.org')
        # Extrai o UUID do MangaDex (ex: title/uuid/nome)
        uuid_match = url.match(/title\/([a-f0-9\-]{36})/)
        return 'md_id', (uuid_match ? uuid_match[1] : url)
      elsif url.include?('mangaplus.shueisha.co.jp')
        return 'mp_url', url
      else
        return 'custom_url', url
      end
    end
  end
end
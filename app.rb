# app.rb
require_relative 'config/environment'
require_relative 'lib/manga_model'
require 'json'

# A Mágica Inicial: Garante que a tabela existe antes do Sinatra abrir as portas.
# Se o senhor apagou o banco sem querer, ele recria na hora.
MangaModel.setup

# Configurações do Sinatra para o Puma não engolir sua RAM
set :bind, '0.0.0.0' # Escuta em todas as interfaces da sua rede local
set :port, 4567      # A porta clássica do Sinatra

# Rota de teste só para o senhor abrir no navegador e ver se o i3 não morreu
get '/' do
  "Mangofier está vivo, mestre. O Proxmox resiste."
end

# A Rota Principal: Onde o Pessegram vai injetar os links
post '/update_link' do
  # Como somos civilizados, esperamos um JSON bonitinho do Pessegram
  request.body.rewind
  payload = JSON.parse(request.body.read) rescue {}

  mu_id = payload['mu_id']
  url = payload['url']

  # Validação nível "Lei de Murphy": O Pessegram mandou os dados certos?
  if mu_id.nil? || url.nil? || url.empty?
    status 400
    return { erro: "Mestre, o Pessegram mandou lixo. Faltam dados." }.to_json
  end

  # O Cérebro Roteador (A triagem preguiçosa com Regex)
  # Identificamos de onde é o link para salvar na coluna certa do SQLite
  tipo_coluna = if url.include?('mangadex.org')
                  # Extrai o ID do MangaDex da URL (ex: title/1234-abcd/nome -> 1234-abcd)
                  # Se a URL vier estranha, joga a URL inteira no custom_url e o senhor que chore depois.
                  md_id_match = url.match(/title\/([a-f0-9\-]+)/)
                  url = md_id_match[1] if md_id_match
                  'md_id'
                elsif url.include?('mangaplus.shueisha.co.jp')
                  'mp_url'
                else
                  'custom_url' # A famosa "lixeira digital" para os sites duvidosos
                end

  begin
    # Tentamos salvar usando os Prepared Statements que criamos no passo anterior
    MangaModel.update_link(mu_id, tipo_coluna, url)
    
    status 200
    { status: "sucesso", mensagem: "Link salvo com sucesso na coluna #{tipo_coluna}. A preguiça venceu." }.to_json
  
  rescue => e
    # Se o banco estiver travado ou der qualquer outro erro catastrófico
    status 500
    { erro: "O servidor chorou: #{e.message}" }.to_json
  end
end
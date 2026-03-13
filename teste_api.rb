require 'faraday'
require 'dotenv/load'
require 'pp' # Biblioteca nativa do Ruby para imprimir JSON bonitinho

puts "🔍 Ligando o Raio-X no teste_api.rb..."

conn = Faraday.new(url: 'https://api.mangaupdates.com/v1') do |f|
  f.request :json
  f.response :json, parser_options: { symbolize_names: true }
  f.adapter Faraday.default_adapter
end

# 1. Login Rápido
login_resp = conn.put('account/login') { |req| req.body = { username: ENV['MU_USERNAME'], password: ENV['MU_PASSWORD'] } }
token = login_resp.body[:context][:session_token]

# 2. Pega IDs (Gaveta 0)
list_resp = conn.post('series/search') do |req|
  req.headers['Authorization'] = "Bearer #{token}"
  req.body = { list_id: 0 }
end
ids = list_resp.body[:results].map { |i| i.dig(:record, :series_id) }.compact

# 3. Pega Lançamentos em Lote
rel_resp = conn.post('releases/search') do |req|
  req.body = { series_id: ids }
end

fofocas = rel_resp.body[:results]

if fofocas && !fofocas.empty?
  puts "\n🧐 MESTRE, OLHE A ESTRUTURA EXATA DO PRIMEIRO ITEM:"
  pp fofocas.first
else
  puts "🚨 A API não devolveu fofoca nenhuma! O Array veio vazio."
end
require 'faraday'
require 'dotenv/load'

puts "🩺 Ligando o Estetoscópio no Abobrinator..."

conn = Faraday.new(url: 'https://api.mangaupdates.com/v1') do |f|
  f.request :json
  f.response :json, parser_options: { symbolize_names: true }
  f.adapter Faraday.default_adapter
end

login_resp = conn.put('account/login') { |req| req.body = { username: ENV['MU_USERNAME'], password: ENV['MU_PASSWORD'] } }
token = login_resp.body.dig(:context, :session_token)

# 1. Pega as obras da gaveta
list_resp = conn.post('series/search') do |req|
  req.headers['Authorization'] = "Bearer #{token}"
  req.body = { list_id: 0 }
end

mapa = {}
list_resp.body[:results].each do |item|
  id = item.dig(:record, :series_id) || item.dig(:record, :id)
  titulo = item.dig(:record, :title)
  mapa[titulo] = id
end

# 2. Pega as fofocas
rel_resp = conn.post('releases/search') do |req|
  req.body = { series_id: mapa.values }
end

puts "\n--- O TESTE DO DETETIVE ---"
rel_resp.body[:results].first(3).each do |item|
  f = item[:record] || item
  titulo = f[:title]
  
  puts "📖 Fofoca recebida: '#{titulo}'"
  puts "   - ID camuflado na fofoca: #{f[:id]}"
  puts "   - ID que o dicionário encontrou: #{mapa[titulo].inspect}"
  
  if mapa[titulo].nil?
    match_parcial = mapa.keys.find { |k| k.to_s.downcase.include?(titulo.to_s.downcase.split.first) }
    puts "   ⚠️ O dicionário falhou! Nome parecido no banco deles: '#{match_parcial}'"
  end
  puts "--------------------------------------"
end
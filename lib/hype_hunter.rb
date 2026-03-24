# lib/hype_hunter.rb
# Hype Hunter - O Caçador de Tendências do Pollux
# Lógica de cálculo de hype baseada em dados do MangaUpdates

class HypeHunter
  # Constantes de configuração
  MAX_RANK = 2000           # Posição máxima aceita
  MIN_RATING = 7.0          # Rating mínimo aceito
  HYPER_COOLDOWN_DAYS = 7   # Dias mínimos entre hype do mesmo mangá
  MAX_HYPE_PER_MANGA = 3    # Máximo de vezes que um mangá pode ser hypeado

  def initialize(manga_updates)
    @mu = manga_updates
  end

  # Busca e analisa lançamentos da semana
  # @param weeks_back [Integer] Quantas semanas atrás (1 = última semana)
  # @return [Array<Hash>] Mangás ranqueados por hype
  def fetch_and_analyze(weeks_back = 1)
    # Calcula data de início (7 dias atrás)
    start_date = (Time.now - (weeks_back * 7 * 24 * 3600)).strftime('%Y-%m-%d')

    puts "🔍 [HypeHunter] Analisando lançamentos desde #{start_date}..."

    # Busca dados via MangaUpdates API
    releases = @mu.fetch_releases_with_ranking(start_date)
    puts "📊 [HypeHunter] #{releases.length} lançamentos brutos recebidos"

    # Calcula delta para cada release
    releases_with_delta = calculate_deltas(releases)
    puts "📈 [HypeHunter] #{releases_with_delta.length} com delta positivo"

    # Filtra por qualidade
    filtered = filter_by_quality(releases_with_delta)
    puts "🎯 [HypeHunter] #{filtered.length} após filtro de qualidade"

    # Filtra por hype history (anti-repetição)
    filtered = filter_by_hype_history(filtered)
    puts "🔄 [HypeHunter] #{filtered.length} após filtro anti-repetição"

    # Remove duplicatas (mesmo mangá pode ter múltiplos capítulos)
    unique = deduplicate_by_series(filtered)
    puts "📚 [HypeHunter] #{unique.length} séries únicas"

    # Ranqueia por delta
    rank_by_hype(unique)
  end

  # Calcula delta (ascensão no ranking) para cada release
  def calculate_deltas(releases)
    releases.map do |r|
      delta = r[:rank_old] - r[:rank_current]

      next nil if delta <= 0 # Só interessa quem SUBIU

      r.merge(delta_week: delta)
    end.compact
  end

  # Filtra por critérios de qualidade
  def filter_by_quality(releases)
    # Mostra amostra para debug
    if releases.any?
      sample = releases.first
      puts "   🔎 Exemplo: #{sample[:title][0..30]} | rating:#{sample[:bayesian_rating]} status:#{sample[:status]} rank:#{sample[:rank_current]} delta:#{sample[:delta_week]}"
    end

    releases.select do |r|
      next false if (r[:bayesian_rating] || 0) < MIN_RATING
      # Aceita qualquer status que contenha "Ongoing" (ex: "5 Volumes (Ongoing)")
      next false if r[:status] && !r[:status].to_s.include?('Ongoing')
      next false if r[:rank_current] && r[:rank_current] > MAX_RANK

      true
    end
  end

  # Filtra mangás em cooldown ou com muitos hypes
  def filter_by_hype_history(releases)
    releases.select do |r|
      manga = MangaModel.find_by_mu_id(r[:mu_id])

      # Nunca foi hypeado -> libera
      next true unless manga && manga['last_hyped_at']

      # Passou o cooldown -> libera
      days_since = (Time.now.to_i - manga['last_hyped_at']) / 86_400
      next true if days_since >= HYPER_COOLDOWN_DAYS

      # Ainda pode ser hypeado -> libera
      next true if (manga['hype_count'] || 0) < MAX_HYPE_PER_MANGA

      false
    end
  end

  # Remove duplicatas (mantém maior delta)
  def deduplicate_by_series(releases)
    by_series = {}
    releases.each do |r|
      sid = r[:mu_id]
      by_series[sid] = r unless by_series[sid] && by_series[sid][:delta_week] >= r[:delta_week]
    end
    by_series.values
  end

  # Ranqueia por delta (maior ascensão primeiro)
  def rank_by_hype(releases)
    releases.sort_by { |r| -r[:delta_week] }
  end

  # Marca mangás como notificados
  def mark_as_hyped(releases)
    releases.each { |r| MangaModel.mark_as_hyped(r[:mu_id]) }
  end

  # Formata relatório para exibição
  def format_report(releases, limit = 5)
    top = releases.first(limit)

    return '😴 Nenhum mangá hypado encontrado esta semana.' if top.empty?

    lines = ["🔥 **Hype Hunter - Relatório Semanal**\n"]

    top.each_with_index do |r, i|
      lines << "#{i + 1}. *#{r[:title]}* (##{r[:rank_old]} → ##{r[:rank_current]})"
      lines << "   📈 +#{r[:delta_week]} posições | ⭐ #{r[:bayesian_rating]&.round(1)}"
      lines << "   👉 #{r[:url] || "mangaupdates.com/series?id=#{r[:mu_id]}"}"
      lines << ''
    end

    lines << '_Delta: rankings semanais do MangaUpdates_'
    lines.join("\n")
  end
end

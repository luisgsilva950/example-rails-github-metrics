# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# ── Holidays: National (Brazil) + Municipal (Belo Horizonte) ──
# Covers 2025–2027. Run `rails db:seed` to populate.

national_holidays = {
  # 2025
  "2025-01-01" => "Confraternização Universal",
  "2025-04-18" => "Sexta-feira Santa",
  "2025-04-21" => "Tiradentes",
  "2025-05-01" => "Dia do Trabalho",
  "2025-06-19" => "Corpus Christi",
  "2025-09-07" => "Independência do Brasil",
  "2025-10-12" => "Nossa Senhora Aparecida",
  "2025-11-02" => "Finados",
  "2025-11-15" => "Proclamação da República",
  "2025-11-20" => "Dia da Consciência Negra",
  "2025-12-25" => "Natal",
  # 2026
  "2026-01-01" => "Confraternização Universal",
  "2026-04-03" => "Sexta-feira Santa",
  "2026-04-21" => "Tiradentes",
  "2026-05-01" => "Dia do Trabalho",
  "2026-06-04" => "Corpus Christi",
  "2026-09-07" => "Independência do Brasil",
  "2026-10-12" => "Nossa Senhora Aparecida",
  "2026-11-02" => "Finados",
  "2026-11-15" => "Proclamação da República",
  "2026-11-20" => "Dia da Consciência Negra",
  "2026-12-25" => "Natal",
  # 2027
  "2027-01-01" => "Confraternização Universal",
  "2027-03-26" => "Sexta-feira Santa",
  "2027-04-21" => "Tiradentes",
  "2027-05-01" => "Dia do Trabalho",
  "2027-05-27" => "Corpus Christi",
  "2027-09-07" => "Independência do Brasil",
  "2027-10-12" => "Nossa Senhora Aparecida",
  "2027-11-02" => "Finados",
  "2027-11-15" => "Proclamação da República",
  "2027-11-20" => "Dia da Consciência Negra",
  "2027-12-25" => "Natal"
}

municipal_holidays = {
  # Belo Horizonte - 2025
  "2025-03-03" => "Segunda-feira de Carnaval",
  "2025-03-04" => "Terça-feira de Carnaval",
  "2025-08-15" => "Assunção de Nossa Senhora",
  "2025-12-08" => "Imaculada Conceição",
  # Belo Horizonte - 2026
  "2026-02-16" => "Segunda-feira de Carnaval",
  "2026-02-17" => "Terça-feira de Carnaval",
  "2026-08-15" => "Assunção de Nossa Senhora",
  "2026-12-08" => "Imaculada Conceição",
  # Belo Horizonte - 2027
  "2027-02-08" => "Segunda-feira de Carnaval",
  "2027-02-09" => "Terça-feira de Carnaval",
  "2027-08-15" => "Assunção de Nossa Senhora",
  "2027-12-08" => "Imaculada Conceição"
}

national_holidays.each do |date_str, name|
  Holiday.find_or_create_by!(date: date_str) do |h|
    h.name = name
    h.scope = "national"
  end
end

municipal_holidays.each do |date_str, name|
  Holiday.find_or_create_by!(date: date_str) do |h|
    h.name = name
    h.scope = "municipal"
  end
end

puts "Seeded #{Holiday.count} holidays."

require 'open-uri'
require 'fileutils'
require 'csv'

YEAR = "15"

def create_dir(path)
  FileUtils::mkdir_p(path) unless Dir.exist?(path)
end

# 975 data is missing for now
departements = ((1..95).map(&:to_s) - ['20'] << "2b" << "2a" << (971..976).map(&:to_s)).flatten! - ['975']
departements.map! { |d| d.rjust(2, '0') }

# Get all XLS files
departements.each do |d|
  begin
    link = "https://www.impots.gouv.fr/portail/files/media/stats/rei_#{YEAR}_#{d}.xls"
    filename = URI(link).path.split('/').last
    dirpath = './tmp/'
    create_dir(dirpath)
    filepath = "#{dirpath}#{filename}"
    unless File.exists?(filepath)
      download = open(link)
      IO.copy_stream(download, filepath)
    end
  rescue OpenURI::HTTPError
    next
  end
end

# Convert each sheets of each xls doc to a single CSV
# You need ssconvert : sudo apt-get install gnumeric
departements.each do |d|
  system("ssconvert -S tmp/rei_#{YEAR}_#{d}.xls tmp/rei_#{YEAR}_#{d}_%s.csv")
  # Add departement code and trailing zeroes to commune code in first column for each csv, for each category
  #
  %w(TH FB FNB CFE).each do |cat|
    `awk 'BEGIN{FS=OFS=\",\"} NR> 6 { $1=sprintf(\"%03d\", $1);$1=\"#{d.upcase}\"$1}1' tmp/rei_#{YEAR}_#{d}_#{cat}.csv > tmp/rei_#{YEAR}_#{d}_#{cat}_clean.csv`
  end
  # TaxesAnnexes : later
end

create_dir('./output')

# Merge all CSVs for each cat into one
# there is a 2-line count error probably because of wrong delimiter in origin csv files
system("awk 'FNR < 7{next;}{print}' ./tmp/*_TH_clean.csv > ./output/taxe_habitation.csv")
system("awk 'FNR < 7{next;}{print}' ./tmp/*_FB_clean.csv > ./output/taxe_fonciere_bati.csv")
system("awk 'FNR < 7{next;}{print}' ./tmp/*_FNB_clean.csv > ./output/taxe_fonciere_non_bati.csv")
system("awk 'FNR < 7{next;}{print}' ./tmp/*_CFE_clean.csv > ./output/taxe_cfe.csv")

# Add a one-line header to output CSV files
system("sed -i.bak 1i'code_insee, nom_commune, base_nette_commune, taux_commune, produit_commune, base_nette_syndicat, taux_syndicat, produit_syndicat, base_nette_interco, taux_interco, produit_interco, base_nette_tse, taux_tse, produit_tse' ./output/taxe_cfe.csv")
system("sed -i.bak 1i'code_insee, nom_commune, base_nette_commune, taux_commune, produit_commune, base_nette_syndicat, taux_syndicat, produit_syndicat, base_nette_interco, taux_interco, produit_interco base_nette_departement, taux_departement, produit_departement, base_nette_tse, taux_tse, produit_tse' ./output/taxe_fonciere_bati.csv")
system("sed -i.bak 1i'code_insee, nom_commune, base_nette_commune, taux_commune, produit_commune, base_nette_syndicat, taux_syndicat, produit_syndicat, base_nette_interco, taux_interco, produit_interco, base_nette_tse, taux_tse, produit_tse, base_nette_add_tax_fnb_commune, taux_add_tax_fnb_commune, produit_add_tax_fnb_commune, base_nette_add_tax_fnb_interco, taux_add_tax_fnb_interco, produit_add_tax_fnb_interco' ./output/taxe_fonciere_non_bati.csv")
system("sed -i.bak 1i'code_insee, nom_commune, base_nette_commune, taux_commune, produit_commune, base_nette_syndicat, taux_syndicat, produit_syndicat, base_nette_interco, taux_interco, produit_interco, base_nette_tse, taux_tse, produit_tse' ./output/taxe_habitation.csv")

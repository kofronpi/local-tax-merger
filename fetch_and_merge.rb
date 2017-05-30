require 'open-uri'
require 'fileutils'
require 'csv'

YEAR = "15"

def create_dir(path)
  FileUtils::mkdir_p(path) unless Dir.exist?(path)
end

# def clean_insee_code(code, departement)
#   "#{departement}#{code.rjust(3, '0')}"
# end

departements = ((1..95).map(&:to_s) - ['20'] << "2b" << "2a" << (971..976).map(&:to_s)).flatten!
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
  # current_csv_th = CSV.parse("rei_#{YEAR}_#{d}_TH.csv")
  # current_csv_th_by_columns = current_csv_th.transpose
  # Add departement AND trailing zeroes to commune code in first column for each csv, for each category
  # system("gawk 'NR > 7 {$1="printf("#{d}%03d\n", $1)" ; print }' tmp/rei_#{YEAR}_#{d}_TH.csv")
end

create_dir('./output')
# Merge all CSVs for TH into one
# there is a 2-line count error probably because of wrong delimiter in origin csv files
system("gawk 'FNR < 7{next;}{print}' *_TH.csv > ./output/taxe_habitation.csv")

# gawk -F, 'NR > 6 { sprintf("%03f", $1) ; print }' tmp/rei_15_01_TH.csv
# gawk 'NR > 7 { $1="01$1" ; print }' tmp/rei_15_01_TH.csv

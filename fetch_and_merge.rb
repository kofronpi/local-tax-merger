require 'open-uri'
require 'fileutils'
require 'csv'

YEAR = "15"

def create_dir(path)
  FileUtils::mkdir_p(path) unless Dir.exist?(path)
end

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
  # Add departement code and trailing zeroes to commune code in first column for each csv, for each category
  # TH
  `awk 'BEGIN{FS=OFS=\",\"} NR> 6 { $1=sprintf(\"%03d\", $1);$1=\"#{dd}\"$1}1' tmp/rei_#{YEAR}_#{dd}_TH.csv > tmp/rei_#{YEAR}_#{dd}_TH_clean.csv`
end

dd = '01'
create_dir('./output')
# Merge all CSVs for TH into one
# there is a 2-line count error probably because of wrong delimiter in origin csv files
system("awk 'FNR < 7{next;}{print}' *_TH_clean.csv > ./output/taxe_habitation.csv")

# Remove all in tmp folder

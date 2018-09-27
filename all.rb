#!/usr/bin/env ruby

# ========================================================================================
# Documentation (Warning): 
# ========================================================================================
# Author: David J. Davis
# 
# This is a messy command line script for doing quick data manipulation. I ingored lint errors
# formatting, style, and overall best practices because these are quick one off scripts that I
# might reuse later.  Please reserve all judgement and understand that this was simply
# a CLI script for quick and dirty data manipulation.
# USE AT YOUR OWN RISK or PLEASURE. 


# REQUIRE LIBS
require 'progress_bar'
require 'xmlsimple'
require 'active_support/core_ext/hash'  #from_xml 
require 'json'
require 'csv'
require 'pry'

# CONSTANTS FOR FILE PATHS 
IMPORT_PATH =  "#{File.expand_path( __dir__)}/sample_data/gen_test_data/"
OUTPUT_FILE =  "#{File.expand_path( __dir__)}/exports/#{Time.now.to_i}_etd.csv"
LOG_FILE =  "#{File.expand_path( __dir__)}/exports/#{Time.now.to_i}_log.txt"
MODIFIED_PATH = "#{File.expand_path( __dir__)}/modified/"
CDATA_REGEX = /!\[CDATA\[(.*?)\]\]>/
SIDECAR_DATA_FILE = "#{File.expand_path('..', __dir__)}/tmp/.data_file.json"

# ========================================================================================
# START HELPER FUNCTIONS 
# ========================================================================================
# Notes:  These were mostly ripped from another project I did with like data. 
# The only real important one is the normalize function, it really needs looked at and
# potentially written better and more performant.

# user prompt method.  Really just lets you get a quick file count and informs you at the
# keyboard what is happening.
def user_prompt
  puts "You are importing from #{IMPORT_PATH}, #{file_count} xml files,
      do you want to proceed? [y|yes|n|no]"
  answer = gets.chomp.downcase
  yes_answers = ['y', 'yes']
  if yes_answers.include?(answer)
    # do something
  else
    abort "You answered - #{answer}, so we did not proceed."
  end
end

# count files
def file_count
  Dir[File.join(IMPORT_PATH, '**', '*')].count { |file| File.file?(file) }
end

# TODO THIS SHOULD BE A RUBY MONKEY PATCH ON THE HASH METHOD
def normalize(keys, hash)
  keys.each do |k| 
    hash[k] = '' unless hash.key?(k)
  end
  return hash
end

# ========================================================================================
# END HELPER FUNCTIONS
# ========================================================================================

user_prompt
bar = ProgressBar.new((file_count * 4), :bar, :rate, :eta)
csv_hashes = []

Dir.foreach(IMPORT_PATH) do |file|
  # ignore hidden files
  hidden_files = ['.', '..']
  next if hidden_files.include? file
  bar.increment!

  # Read and Format the data for information extraction
  data = File.read([IMPORT_PATH, file].join)
  # whitespace in some records is keeping the CDATA from being grabbed
  data.gsub!(/\n/, '') 
  # URLS are pointless for our usecase Just want to strip them out 
  data.gsub!(/<urls>.*?<\/urls>/, '') 
  # create new XML from modied information
  cdata = data.scan(CDATA_REGEX)
  record_xml = data.scan(/<record.*?>.*?<\/record>/)[0]
  object_xml = data.scan(/<object.*?>.*?<\/object>/)[0]
  pid = data.scan(/<pid.*?>.*?<\/pid>/)[0]
  stream = data.scan(/<stream_ref>.*?<\/stream_ref>/)[0]

  if record_xml.nil? || object_xml.nil? 
    File.open(LOG_FILE, 'a+') {|f| f.write("#{file}- Did not contain record or object data.\n") }
    next
  end

  new_xml = '<?xml version="1.0" encoding="UTF-8"?>'
  new_xml << '<docs>'
  new_xml << record_xml
  new_xml << object_xml
  new_xml << pid.to_s
  new_xml << stream.to_s
  new_xml << '</docs>'

  xml_hash = Hash.from_xml(new_xml)
  xml_hash.deep_symbolize_keys!

  csv_hash = {}

  # clean up records hash 
  records = xml_hash[:docs][:record].except!(:"xmlns:dc", :"xmlns:dcterms", :"xmlns:xsi")
  records.each do |key,value| 
    if value.class == Array
      csv_hash.store(key, value.join('; '))
    else
      csv_hash.store(key, value)
    end 
  end

  objects = xml_hash[:docs][:object]
  objects.each do |key,value|
    if value.class == Array
      csv_hash.store(key, value.join('; '))
    else
      csv_hash.store(key, value)
    end 
  end

  pid = xml_hash[:docs][:pid]
  csv_hash.store(:pid, pid)

  stream = xml_hash[:docs][:stream_ref]
  stream.each do |key,value| 
    next if value.class == Hash
    if value.class == Array
      csv_hash.store(key, value.join('; '))
    else
      csv_hash.store(key, value)
    end 
  end

  # store filename 
  csv_hash.store(:xml_filename, file)
  
  # save it to the array
  csv_hashes << csv_hash
end

# DETERMINE KEYS FOR THE CSV DOCUMENT
all_hash_keys = []
csv_hashes.each do |h|
  bar.increment!
  all_hash_keys = all_hash_keys | h.keys
end

# Normalize all values in the hash so the CSV Data matches 
normalized_hashes = []
csv_hashes.each do |h|
  bar.increment!
  nrml_hash = normalize(all_hash_keys, h)
  normalized_hashes << nrml_hash
end 


# Create the CSV
csv_data = CSV.generate(headers: true) do |csv|
  titles = normalized_hashes.first.sort.to_h.keys
  csv << titles
  normalized_hashes.each do |hash|
    bar.increment!
    csv << hash.sort.to_h.values.map { |v| "#{v}" }
  end
end
File.open(OUTPUT_FILE, 'w+') { |f| f.write(csv_data) }

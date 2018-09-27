#!/usr/bin/env ruby

require 'faker'
require 'active_support/core_ext/hash'  #from_xml 

1000.times do |i|
  test_data = {
    pid: rand(10000...999546),
    record: { 
      creator: Faker::LordOfTheRings.character, 
      spatial: Faker::LordOfTheRings.location, 
      agent: Faker::Educator.university,
      subject: Faker::Lorem.characters(10),
      college: Faker::Educator.campus, 
      committeeChair: Faker::GameOfThrones.character,
      abstract: Faker::Simpsons.quote
    }, 
    object: { 
      objectType: 'handle', 
      objectIdentifier: Faker::Lorem.characters(10)
    }, 
    stream_ref: { 
      file_name: Faker::Lorem.characters(10), 
		  file_extension: Faker::File.extension, 
		  mime_type: Faker::File.mime_type, 
		  directory_path: Faker::File.file_name('path/to'),
		  file_id: rand(10000...999546),
		  storage_id: rand(10000...999546),
		  external_type: rand(10000...999546),
		  file_size_bytes: "#{rand(1..200) * 16}"
    }
  }
  xml = test_data.to_xml(root: 'doc')
  directory_name = 'gen_test_data'
  directory_path = "#{File.expand_path( __dir__)}/sample_data/#{directory_name}"
  Dir.mkdir(directory_path) unless File.exists?(directory_path)
  xml_string = xml.to_s.gsub('stream-ref', 'stream_ref')
  File.open("#{directory_path}/test_#{i}.xml", 'w+') { |f| f.write(xml_string) }
end

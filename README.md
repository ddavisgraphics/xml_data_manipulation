# XML Documents to CSV 
The following is just for working with XML Documents exported from Digitool for injest into BePress.  The script simply iterates through a directory of xml files, pulls out certain information, and puts that information into hashes.  These hashes are then normalized and turned into CSV files so that our librarians can import them into Metadata software and modify them as needed import into the new system.  

# XML Document Info
- `<pid>####</pid>` - This is the personal identifier of each record in the system.  There are many of these so, we want to make sure that we are collecting only the top level PID or the first one in the document.  
- `<record></record>` - This is where all of the dublin core data is currently located, however there is extra information in this tag that we will have to strip out so that the XML will parse properly.  
- `<object></object>` - This is where all of the object ID and Handle ID's are currently located.  It is important that these remain intact in some location.  Some of the records do not have the correct markup or have a different markup.  Send this entire object to the CSV and let the users parse the appropriate information out.  
- The XML files are not valid, this is going to cause problems parsing with simple gems like Nokogiri, which was my first choice for searching and finding information.  
- None of the XML files conform to all of the same standards, for certain XML exported you will have to turn off collection of the object tag.  

# DEPENDENCIES
  - ruby >= 2.3 
  - faker!
  - progress_bar
  - rails (active support only)
  - xml-simple (~> 1.1, >= 1.1.5)

# WARNING
This is a messy command line script for doing quick data manipulation. I ingored lint errors formatting, style, and overall best practices because these are quick one off scripts that I might reuse later.  Please reserve all judgement and understand that this was simply a CLI script for quick and dirty data manipulation.
**USE AT YOUR OWN RISK [or] PLEASURE.**

# Test Data
You can run `ruby generate_test_data.rb` to generate test data xml files, it should get you close if your having to tweak the script, but it will not take into account edge cases and sloppy XML which seems to be part of this entire process.  Mainly it provides a way for you to see what the script is doing and how it generates the data. 

# User
Modify the CONST file paths in the all.rb file to your file path and run `ruby all.rb`.  Sit back and watch the progress bar.  

# Errors / Poor Data
If no data exists in the record or object methods, then the file will be skipped and mentioned in the log file that will generate in the export.  It will have the same timestamp at the start of the text file as the csv does. The test data shows this is two records. 
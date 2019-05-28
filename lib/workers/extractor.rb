require 'csv'
require 'open-uri'
require 'set'

class Extractor
    REQUIRED_COLUMN = ['CAMIS', 'DBA', 'BORO', 'BUILDING', 'STREET', 'ZIPCODE', 'PHONE', 'GRADE', 'GRADE DATE']
    VALID_GRADES = Set.new(%w(A B C N P Z))

    #TODO add timestamp to initialize for file creation

    def do_work
        File.open('DOHMH_New_York_City_Restaurant_Inspection_Results.csv') do |f|
        #open('https://data.cityofnewyork.us/api/views/43nn-pn8j/rows.csv') do |file|
            CSV.open(f, headers: true, return_headers: true) do |csv|
                inspection_results = csv.each
                stage_extracted_data(inspection_results)
            end
        end
    end

    private

    def stage_extracted_data(inspection_results)
        total_rows = 0
        invalid_rows = 0

        # TODO: use temp file mechanism
        File.open('valid_inspection_results.csv', 'w') do |f|
            inspection_results.each do |row|
                if !row.header_row?
                    total_rows += 1

                    if !is_valid_row?(row)
                        invalid_rows += 1
                        next
                    end
                end

                f.puts(row.to_s)
            end
        end

        puts "#{invalid_rows} invalid rows out of #{total_rows} total rows"
    end

    def is_valid_row?(row)
        is_valid = REQUIRED_COLUMN.reduce(true) { |memo, name| memo && !row[name].nil? }
        is_valid && VALID_GRADES.include?(row['GRADE'])
    end
end

Extractor.new.do_work
require 'csv'
require 'open-uri'
require 'set'

class Extractor
    RESTAURANT_INSPECTION_RESULTS_URL = 'https://data.cityofnewyork.us/api/views/43nn-pn8j/rows.csv'
    REQUIRED_COLUMN = ['CAMIS', 'DBA', 'BORO', 'BUILDING', 'STREET', 'ZIPCODE', 'PHONE', 'GRADE', 'GRADE DATE']
    VALID_GRADES = Set.new(%w(A B C N P Z))


    def initialize(run_id)
        @run_id = run_id
        @output_filepath = "/tmp/extracted_inspection_results_#{@run_id}.csv"
    end

    def do_work(_, output_io)
        csv = get_restaurant_inspection_results
        stage_extracted_data(csv, output_io)

        puts "Extractor job #{@run_id} completed"
    rescue => e
        abort "Extractor job #{@run_id} failed: #{e.to_s}"
    ensure
        csv.close
    end

    private

    def get_restaurant_inspection_results
        CSV.open(open(RESTAURANT_INSPECTION_RESULTS_URL), headers: true, return_headers: true)
    end

    def stage_extracted_data(inspection_results, output_io)
        total_rows = 0
        invalid_rows = 0
 
        inspection_results.each do |row|
            if !row.header_row?
                total_rows += 1

                if !is_valid_row?(row)
                    invalid_rows += 1
                    next
                end
            end

            output_io.write(row.to_s)
        end

        if invalid_rows > 0
            puts "Extractor job #{@run_id} filtered out #{invalid_rows} invalid rows out of #{total_rows} total rows"
        end
    end

    def is_valid_row?(row)
        is_valid = REQUIRED_COLUMN.reduce(true) { |memo, name| memo && !row[name].nil? }
        is_valid && VALID_GRADES.include?(row['GRADE'])
    end
end
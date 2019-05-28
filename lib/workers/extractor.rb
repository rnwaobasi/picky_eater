require 'csv'
require 'open-uri'
require 'set'

class Extractor
    REQUIRED_COLUMN = ['CAMIS', 'DBA', 'BORO', 'BUILDING', 'STREET', 'ZIPCODE', 'PHONE', 'GRADE', 'GRADE DATE']
    VALID_GRADES = Set.new(%w(A B C N P Z))

    def initialize(run_id)
        @run_id = run_id
    end

    def do_work
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        output_filepath = "/tmp/extracted_inspection_results_#{@run_id}.csv"
        open('https://data.cityofnewyork.us/api/views/43nn-pn8j/rows.csv') do |file|
            CSV.open(file, headers: true, return_headers: true) do |csv|
                inspection_results = csv.each
                stage_extracted_data(output_filepath, inspection_results)
            end
        end

        elapsed_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

        puts "Extractor job #{@run_id} completed in #{elapsed_time}"
    rescue => e
        File.delete(filepath) if File.exist?(filepath)
        abort "Extractor job #{@run_id} failed: #{e.to_s}"
    end

    private

    def stage_extracted_data(output_filepath, inspection_results)
        total_rows = 0
        invalid_rows = 0

        File.open(output_filepath, 'w') do |f|
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

        puts "Extractor job #{@run_id} filtered out #{invalid_rows} invalid rows out of #{total_rows} total rows"
    end

    def is_valid_row?(row)
        is_valid = REQUIRED_COLUMN.reduce(true) { |memo, name| memo && !row[name].nil? }
        is_valid && VALID_GRADES.include?(row['GRADE'])
    end
end
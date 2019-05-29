require 'securerandom'

require_relative './extractor'
require_relative './transformer'
require_relative './loader'

def main
    run_id = SecureRandom.uuid
    workers = [Extractor.new(run_id), Transformer.new(run_id), Loader.new(run_id)]
    
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    
    workers.each { |worker| worker.do_work }

    elapsed_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
    puts "ETL job #{run_id} completed in #{elapsed_time}"
end

main
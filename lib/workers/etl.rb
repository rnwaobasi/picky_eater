require 'securerandom'
require 'tempfile'

require_relative './extractor'
require_relative './transformer'
require_relative './loader'

def main
    run_id = SecureRandom.uuid
    extractor_out_transformer_in = Tempfile.new('extracted_restaurant_inspection')
    transformer_out_loader_in = {
        restaurants: Tempfile.new('restaurants_csv'),
        locations: Tempfile.new('locations_csv'),
        restaurant_locations: Tempfile.new('restaurant_locations_csv'),
    }

    worker_configs = [
        {
            worker: Extractor.new(run_id),
            ios: {input: nil, output: extractor_out_transformer_in}
        },
        {
            worker: Transformer.new(run_id),
            ios: {input: extractor_out_transformer_in, output: transformer_out_loader_in}
        },
        {
            worker: Loader.new(run_id),
            ios: {input: transformer_out_loader_in, output: nil}
        }
    ]

    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    
    worker_configs.each do |config|
        config[:worker].do_work(config[:ios][:input], config[:ios][:output])
    end

    elapsed_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
    puts "ETL job #{run_id} completed in #{elapsed_time}"
end

main
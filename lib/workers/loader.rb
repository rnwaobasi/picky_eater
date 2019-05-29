require 'csv'
require 'date'
require 'set'
require_relative '../db/datastore'

class Loader
    def initialize(run_id)
        @run_id = run_id
    end

    def do_work(input_io, _)
        restaurants_csv = input_io[:restaurants]
        locations_csv = input_io[:locations]
        restaurant_locations_csv = input_io[:restaurant_locations]
        DB::DS.load_restaurant_inspection_model(restaurants_csv, locations_csv, restaurant_locations_csv)

        puts "Loader job #{@run_id} completed"
    rescue => e
        abort "Loader job #{@run_id} failed: #{e.to_s}"
    end
end

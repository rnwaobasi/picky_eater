require 'csv'
require 'date'
require 'set'
require_relative '../db/datastore'

class Loader
    def initialize(run_id)
        @run_id = run_id
    end

    def do_work
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        restaurants_filepath = "/tmp/restaurants_#{@run_id}.csv"
        locations_filepath = "/tmp/locations_#{@run_id}.csv"
        restaurant_locations_filepath = "/tmp/restaurant_locations_#{@run_id}.csv"

        restaurants_csv = File.open(restaurants_filepath)
        locations_csv = File.open(locations_filepath)
        restaurant_locations_csv = File.open(restaurant_locations_filepath)
        DB::DS.load_restaurant_inspection_model(restaurants_csv, locations_csv, restaurant_locations_csv)

        File.delete(restaurants_filepath)
        File.delete(locations_filepath)
        File.delete(restaurant_locations_filepath)

        elapsed_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

        puts "Loader job #{@run_id} completed in #{elapsed_time}"
    rescue => e
        abort "Loader job #{@run_id} failed: #{e.to_s}"
    ensure
        restaurants_csv.close
        locations_csv.close
        restaurant_locations_csv.close
    end
end


require 'pg'
require 'sequel'

module::DB
    class Datastore
        def initialize
            @db = Sequel.connect(ENV['DATABASE_URL'])
        end

        def load_restaurant_inspection_model(restaurants_csv, locations_csv, restaurant_locations_csv)
            @db.transaction do
                @db.alter_table :restaurant_locations do
                    drop_foreign_key [:restaurant_camis]
                    drop_foreign_key [:location_id]
                end

                @db[:restaurant_locations].truncate
                @db[:restaurants].truncate
                @db[:locations].truncate

                @db.alter_table :restaurant_locations do
                    add_foreign_key [:restaurant_camis], :restaurants, unique: true
                    add_foreign_key [:location_id], :locations
                end

                @db.copy_into(:restaurants, data: restaurants_csv, format: :csv, options: 'HEADER true')
                @db.copy_into(:locations, data: locations_csv, format: :csv, options: 'HEADER true')
                @db.copy_into(:restaurant_locations, data: restaurant_locations_csv, format: :csv, options: 'HEADER true')
            end
        end
    end

    DS = Datastore.new
end

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

        def get_restaurants(params)
            # Unfortunately, Sequel doesn't play nice if keys of params hash are not symbols
            params_with_symbols = params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

            @db[:restaurants]
                .select(:camis, :dba, :phone, :cuisine, :grade, :grade_date, :building, :street, :boro, :zipcode)
                .join_table(:inner, :restaurant_locations, restaurant_camis: :camis)
                .join_table(:inner, :locations, id: :location_id)
                .where(params_with_symbols).all
        end
    end

    DS = Datastore.new
end
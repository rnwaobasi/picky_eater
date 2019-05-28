require 'csv'
require 'date'
require 'set'

class Transformer
    COLUMN_ORDER = {
        restaurants: [:camis, :dba, :phone, :cuisine, :grade, :grade_date],
        locations: [:id, :street, :building, :boro, :zipcode],
        restaurant_locations: [:restaurant_camis, :location_id]
    }

    def initialize(run_id)
        @run_id = run_id
    end

    def do_work(input_io, output_io)
        csv = CSV.open(input_io, headers: true)
        normalized_data = normalize_inspection_results(csv)
        stage_normalized_data(normalized_data, output_io)

        puts "Transformer job #{@run_id} completed"
    rescue => e
        abort "Transformer job #{@run_id} failed: #{e.to_s}"
    ensure
        csv.close
    end

    private

    def normalize_inspection_results(inspection_results)
        location_id = 1
        location_key_to_id = {}
        restaurant_id_to_info = {}
        restaurant_location_mappings = Set.new
      
        inspection_results.each do |row|
            camis = row['CAMIS']
            restaurant_info = {
                camis: camis,
                dba: row['DBA'],
                phone: row['PHONE'],
                cuisine: row['CUISINE DESCRIPTION'],
                grade: row['GRADE'],
                grade_date: Date.strptime(row['GRADE DATE'], "%m/%d/%Y").to_s
            }

            if restaurant_id_to_info[camis].nil?
                restaurant_id_to_info[camis] = restaurant_info
            else
                grade_date = Date.parse(restaurant_id_to_info[camis][:grade_date])
                other_grade_date = Date.parse(restaurant_info[:grade_date])
                restaurant_id_to_info[camis] = restaurant_info if other_grade_date > grade_date
            end

            location_key = {
                boro: row['BORO'],
                building: row['BUILDING'],
                street:   row['STREET'],
                zipcode: row['ZIPCODE']
            }

            if location_key_to_id[location_key].nil?
                location_key_to_id[location_key] = location_id
                location_id += 1
            end

            restaurant_location_mappings << {restaurant_camis: camis, location_id: location_key_to_id[location_key]}
        end
        
        {
            restaurants: restaurant_id_to_info.values,
            locations: location_key_to_id.map { |location, location_id| location.merge({id: location_id}) },
            restaurant_locations: restaurant_location_mappings.to_a
        }
    end

    def stage_normalized_data(normalized_data, output_io)
        normalized_data.each do |key, data|
            CSV.open(output_io[key], "w") do |csv|
                csv.puts(COLUMN_ORDER[key])

                data.each do |row|
                    csv.puts(COLUMN_ORDER[key].map { |column| row[column] })
                end
            end
        end
    end
end
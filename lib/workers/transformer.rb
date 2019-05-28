require 'csv'
require 'date'
require 'set'

class Transformer
    
    COLUMN_ORDER = {
        restaurants: [:camis, :dba, :phone, :cuisine, :grade, :grade_date],
        locations: [:id, :boro, :building, :street, :zipcode],
        restaurant_location_mappings: [:restaurant_camis, :location_id]
    }

    def do_work
        csv = CSV.open('valid_inspection_results.csv', headers: true)
        normalized_data = normalize_inspection_results(csv.each)
        stage_normalized_data(normalized_data)
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
                grade_date: row['GRADE DATE']
            }

            if restaurant_id_to_info[camis].nil?
                restaurant_id_to_info[camis] = restaurant_info
            else
                grade_date = Date.strptime(restaurant_id_to_info[camis][:grade_date], "%m/%d/%Y")
                other_grade_date = Date.strptime(restaurant_info[:grade_date], "%m/%d/%Y")
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
            restaurant_location_mappings: restaurant_location_mappings.to_a
        }
    end

    def stage_normalized_data(normalized_data)
        normalized_data.each do |key, data|
            CSV.open("#{key}.csv", "w") do |csv|
                csv.puts(COLUMN_ORDER[key])

                data.each do |row|
                    csv.puts(COLUMN_ORDER[key].map { |column| row[column] })
                end
            end
        end
    end
end

Transformer.new.do_work
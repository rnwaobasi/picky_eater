require 'stringio'

require 'workers/loader'
require 'db/datastore'

describe Loader do
    let(:loader) { Loader.new('test') }

    describe '#do_work' do
        it 'makes call to load the restaurant inspect model into database' do
            restaurants_output = "camis,dba,phone,grade,grade_date\n" \
                "45667,restaurant 1,1234567890,A,01/01/2019\n"
                "5678,restaurant 2,1234567890,A,01/01/2019\n" \
                "7747,restaurant 3,1234567890,C,01/01/2019\n"

            locations_output = "id,street,building,boro,zipcode\n" \
                "1,123,some street,BROOKLYN,11205\n" \
                "2,456,some street,MANHATTAN,10001\n"

            restaurant_locations_output = "restaurant_camis,location_id\n" \
                "45667,1\n" \
                "5678,2\n" \
                "7747,2\n"

            input = {
                restaurants: StringIO.new(restaurants_output),
                locations: StringIO.new(locations_output),
                restaurant_locations: StringIO.new(restaurant_locations_output),
            }

            expect(DB::DS).to receive(:load_restaurant_inspection_model).with(input[:restaurants], input[:locations], input[:restaurant_locations])

            loader.do_work(input, nil)
        end
    end
end

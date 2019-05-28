require 'workers/transformer'
require 'stringio'
require 'tempfile'

describe Transformer do
    let(:transformer) { Transformer.new('test') }
    let(:input) do
        "CAMIS,DBA,BORO,BUILDING,STREET,ZIPCODE,PHONE,GRADE,GRADE DATE\n" \
        "45667,restaurant 1,BROOKLYN,123,some street,11205,1234567890,B,01/01/2019\n" \
        "45667,restaurant 1,BROOKLYN,123,some street,11205,1234567890,A,02/01/2019\n" \
        "5678,restaurant 2,MANHATTAN,456,some street,10001,1234567890,A,01/01/2019\n" \
        "7747,restaurant 3,MANHATTAN,456,some street,10001,1234567890,C,01/01/2019\n"
    end

    describe '#do_work' do
        it 'normalizes data for reduced redundancy' do
            output = {
                restaurants: StringIO.new(),
                locations: StringIO.new(),
                restaurant_locations: StringIO.new(),
            }

            tmp_input = create_input_temp_file(input)
            transformer.do_work(tmp_input, output)

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

            expect(output[:restaurants]).to eq(restaurants_output)
            expect(output[:locations]).to eq(locations_output)
            expect(output[:restaurant_locations]).to eq(restaurant_locations_output)
        end
    end
end

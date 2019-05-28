require 'workers/extractor'
require 'stringio'
require 'tempfile'

describe Extractor do
    let(:extractor) { Extractor.new('test') }
    let(:valid_input) do
        "CAMIS,DBA,BORO,BUILDING,STREET,ZIPCODE,PHONE,GRADE,GRADE DATE\n" \
        "45667,restaurant 1,BROOKLYN,123,some street,11205,1234567890,A,01/01/2019\n" \
        "5678,restaurant 2,MANHATTAN,456,some street,10001,1234567890,A,01/01/2019\n"
    end

    let(:input_with_invalid_rows) do
        "CAMIS,DBA,BORO,BUILDING,STREET,ZIPCODE,PHONE,GRADE,GRADE DATE\n" \
        "45667,restaurant 1,BROOKLYN,123,some street,11205,1234567890,A,01/01/2019\n" \
        "5678,restaurant 2,MANHATTAN,456,some street,,1234567890,A,01/01/2019\n" \
        "5678,restaurant 2,MANHATTAN,456,some street,10001,1234567890,INVALID,01/01/2019\n"
    end

    describe '#do_work' do
        it 'makes request for restaurant inspection results' do
            tmp = create_input_temp_file(valid_input)
            allow(extractor).to receive(:open).with(Extractor::RESTAURANT_INSPECTION_RESULTS_URL).and_return(tmp)
            expect(extractor).to receive(:open).with(Extractor::RESTAURANT_INSPECTION_RESULTS_URL)
            extractor.do_work(nil, StringIO.new)
        end

        it 'stages retrieved restaurant inspection results' do
            tmp = create_input_temp_file(valid_input)
            allow(extractor).to receive(:open).with(Extractor::RESTAURANT_INSPECTION_RESULTS_URL).and_return(tmp)  
            buffer = StringIO.new()
            extractor.do_work(nil, buffer)

            expect(buffer.string).to eq(valid_input)
        end

        it 'filters out invalid rows' do
            tmp = create_input_temp_file(input_with_invalid_rows)
            allow(extractor).to receive(:open).with(Extractor::RESTAURANT_INSPECTION_RESULTS_URL).and_return(tmp)
            
            buffer = StringIO.new()
            extractor.do_work(nil, buffer)

            output = "CAMIS,DBA,BORO,BUILDING,STREET,ZIPCODE,PHONE,GRADE,GRADE DATE\n" \
                "45667,restaurant 1,BROOKLYN,123,some street,11205,1234567890,A,01/01/2019\n"

            expect(buffer.string).to eq(output)
        end
    end
end

def create_input_temp_file(content)
    temp = Tempfile.new("test")
    temp.print(content)
    temp.rewind
    temp
end

module Helpers
    def create_input_temp_file(content)
        temp = Tempfile.new("test")
        temp.print(content)
        temp.rewind
        temp
    end
end
class ReviewRelationships
    attr_reader :main_response, :related
    
    def initialize(file)
        content = file['response']['links']
        @main_response = content['self']
        @related = content['related']
    end
end
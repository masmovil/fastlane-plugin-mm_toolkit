require_relative './review_attributes'
require_relative './review_relationships'

class Review
    attr_reader :type, :id, :attributes, :relationships
    
    def initialize(type, id, attributes, relationships)
        @type = type
        @id = id
        @attributes = ReviewAttributes.new(attributes)
        @relationships = ReviewRelationships.new(relationships)
    end

    def rows
        {rating: attributes.rating, date: attributes.created_date}
    end  
end
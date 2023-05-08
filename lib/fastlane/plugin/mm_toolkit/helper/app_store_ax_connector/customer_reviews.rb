require_relative './review'
require 'json'
require 'date'

class CustomerReviews
    attr_reader :data, :brand

    def initialize(data)
         @data = data.map { |content|     
            Review.new(content["type"], content["id"], content["attributes"], content["relationships"]) 
        }
        @brand = brand
    end

    def rows
        @data.map { |review|
            {rating: review.attributes.rating, date: review.attributes.created_date}
        }
    end  
end
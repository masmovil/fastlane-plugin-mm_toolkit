require_relative './review'
require 'json'
require 'date'

class CustomerReviews
    attr_reader :data, :brand, :links, :meta

    def initialize(data, brand)
         @data = data.map { |content|     
            Review.new(content["type"], content["id"], content["attributes"], content["relationships"]) 
        }
        @brand = brand
         #@links = links
         #@meta = meta
    end

    def rows
        date_to_search = Date.today.prev_day
        date_to_save = Date.today
        rows =  @data.filter { |item| item.attributes.created_date == date_to_save }
        rows.map { |review|
            {brand: @brand, rating: review.attributes.rating, date: date_to_save}
        }
    end  
end
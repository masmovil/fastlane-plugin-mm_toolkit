# frozen_string_literal: true

class ReviewAttributes
  attr_reader :rating, :title, :body, :reviewer_nickname, :created_date, :territory

  def initialize(file)
    @rating = file["rating"]
    @title = file["title"]
    @body = file["body"]
    @reviewer_nickname = file["reviewerNickname"]
    @created_date = file["createdDate"]
    @territory = file["territory"]
  end
end

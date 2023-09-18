# frozen_string_literal: true

require_relative "review"

class Reviews
  attr_reader :data, :links, :meta

  def initialize(data, links, meta)
    @data = Review.from_json(data)
    @links = links
    @meta = meta
  end

  def self.from_json(file)
    Reviews.new(file["data"], file["links"], file["meta"])
  end
end

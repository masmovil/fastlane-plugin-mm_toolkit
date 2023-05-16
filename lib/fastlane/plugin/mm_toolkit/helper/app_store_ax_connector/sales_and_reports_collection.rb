# frozen_string_literal: true

require "date"
require_relative "sales_and_reports"

class SalesAndReportsCollection
  attr_accessor :items

  def initialize(file)
    csv_text = Zlib::GzipReader.new(StringIO.new(file)).read.force_encoding("UTF-8")
    csv_data = CSV.parse(csv_text, headers: true, col_sep: "\t")
    @items = csv_data.map do |content|
      SalesAndReports.new(content["Provider"], content["Provider Country"], content["SKU"], content["Developer"],
        content["Title"], content["Version"], content["Product Type Identifier"], content["Units"],
        content["Developer Proceeds"], content["Begin Date"], content["End Date"], content["Customer Currency"],
        content["Country Code"], content["Currency of Proceeds"], content["Apple Identifier"],
        content["Customer Price"], content["Promo Code"], content["Parent Identifier"], content["Subscription"],
        content["Period"], content["Category"], content["CMB"], content["Device"], content["Supported Platforms"],
        content["Proceeds Reason"], content["Preserved Pricing"], content["Client"], content["Order Type"])
    end
  end

  def rows
    date_to_save = Date.today
    # Filter with 1F because 1F is a new downloads
    items_grouped_by_brand = @items.filter { |item| item.product_type_identifier == "1F" }.group_by(&:sku)
    items_grouped_by_brand.map do |brand, items|
      total_units = items.map { |item| item.units.to_i }.reduce(0, :+)
      { brand: brand, units: total_units, date: date_to_save }
    end
  end
end

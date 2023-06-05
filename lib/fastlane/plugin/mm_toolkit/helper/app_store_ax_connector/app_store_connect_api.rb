# frozen_string_literal: true

require "httparty"
require "jwt"
require "date"
require_relative "./sales_and_reports_collection"
require_relative "./reviews"
require_relative "./customer_reviews"

class AppStoreConnectAPI
  attr_reader :issuer_id, :key_id, :private_key_content, :vendor_number

  JWT_ALG = "ES256"
  APP_VERSION = "1_0"
  HOST = "api.appstoreconnect.apple.com"
  API_VERSION = "v1"

  def initialize(app_store_connect_account)
    @issuer_id = app_store_connect_account.issuer_id
    @key_id = app_store_connect_account.key_id
    @private_key_content = app_store_connect_account.private_key_content
    @vendor_number = app_store_connect_account.vendor_number
  end

  def get_reviews(app_id, date = nil)
    response = HTTParty.get(customer_reviews_url(app_id), headers: authorization_headers)

    if response.code == 200
      customer_reviews = CustomerReviews.new(response["data"])

      if date.nil?
        customer_reviews.data
      else
        customer_reviews.data.filter do |review|
          review_date = Date.parse(review.attributes.created_date)
          review_date == date
        end
      end
    else
      raise "Reviews download failed! #{response.code} #{response.message}"
    end
  end

  def get_sales_and_reports
    response = HTTParty.get(sales_reports_url, headers: sales_headers)

    if response.code == 200
      SalesAndReportsCollection.new(response.body)
    else
      raise "Sales and reports download failed! #{response.code} #{response.message}"
    end
  end

  private

  def private_key
    OpenSSL::PKey::EC.new(@private_key_content)
  end

  def exp
    Time.now.to_i + 20 * 60 # Expires in 20 minutes
  end

  def headers
    {
      "kid" => key_id,
      "alg" => JWT_ALG,
    }
  end

  def claims
    {
      "iss" => @issuer_id,
      "exp" => exp,
      "aud" => "appstoreconnect-v1",
    }
  end

  def token
    JWT.encode(claims, private_key, JWT_ALG, headers)
  end

  def sales_reports_url(date = nil)
    path = "/#{API_VERSION}/salesReports"

    query_params = {
      "filter[reportType]" => "SALES",
      "filter[reportSubType]" => "SUMMARY",
      "filter[vendorNumber]" => @vendor_number.to_s,
    }

    if !date.nil?
      query_params["filter[frequency]"] = "WEEKLY"
      query_params["filter[reportDate]"] = date
    else
      query_params["filter[frequency]"] = "DAILY"
    end

    query = URI.encode_www_form(query_params)

    URI::HTTPS.build(host: HOST, path: path, query: query)
  end

  def authorization_headers
    {
      "Authorization" => "Bearer #{token}",
    }
  end

  def authorization_json_headers
    {
      "Authorization" => "Bearer #{token}",
      "Content-Type" => "application/json",
    }
  end

  def sales_headers
    {
      "Accept": "application/a-gzip, application/json",
      "Authorization" => "Bearer #{token}",
    }
  end

  def customer_reviews_url(app_id)
    path = "/#{API_VERSION}/apps/#{app_id}/customerReviews"

    query_params = {
      "sort" => "-createdDate",
      "limit" => "200",
    }

    query = URI.encode_www_form(query_params)

    URI::HTTPS.build(host: HOST, path: path, query: query)
  end
end

require 'httparty'
require 'jwt'
require 'date'
require_relative './sales_and_reports_collection'
require_relative './reviews'
require_relative './customer_reviews'

class AppStoreConnectAPI
  attr_reader :issuer_id, :key_id, :private_key_content, :vendor_number, :sales_and_reports_collection, :reviews
  #app_store_connect_account: We need this parameter to setup basic configuration
  #brand: We need this parameter to setup basic configuration
def initialize(app_store_connect_account)
  @issuer_id = app_store_connect_account.issuer_id
  @key_id = app_store_connect_account.key_id
  @private_key_content = app_store_connect_account.private_key_content
  @vendor_number = app_store_connect_account.vendor_number
  @sales_and_reports_collection = nil
  @reviews = nil
end

def private_key
   OpenSSL::PKey::EC.new(@private_key_content)
end

# Build access token
def exp 
  Time.now.to_i + 20 * 60 # Expires in 20 minutes
end

def headers
  {
    'kid' => key_id,
    'alg' => 'ES256'
  }
end

def claims 
  {
    'iss' => @issuer_id,
    'exp' => exp,
    'aud' => 'appstoreconnect-v1'
  }
end

def token 
  JWT.encode(claims, private_key, 'ES256', headers)
end

def report_date
  Date.new(2023, 4, 23).strftime('%Y-%m-%d')
end

def app_version
  "1_0"
end

def base_url
  "https://api.appstoreconnect.apple.com/v1/"
end

def sales_reports_path
  "salesReports"
end
=begin
def sales_reports_query_params
  "?filter[frequency]=WEEKLY&filter[reportDate]=#{report_date}&filter[reportSubType]=SUMMARY&filter[reportType]=SALES&filter[vendorNumber]=#{@vendor_number}&filter[version]=#{app_version}"
end
=end

def sales_reports_query_params
  "?filter[frequency]=DAILY&filter[reportSubType]=SUMMARY&filter[reportType]=SALES&filter[vendorNumber]=#{@vendor_number}"
end

def sales_path_absolute_url
  base_url+sales_reports_path+sales_reports_query_params
end

def authorization_headers
  {
    'Authorization' => "Bearer #{token}"
  }
end

def authorization_json_headers
  {
    'Authorization' => "Bearer #{token}",
    'Content-Type' => 'application/json'
  }
end
def sales_headers
  {
    'Accept': 'application/a-gzip, application/json',
    'Authorization' => "Bearer #{token}"
  }
end

def customer_reviews_path(app_id)
  base_url+"apps/#{app_id}/customerReviews"
end

def get_reviews(app_id)
  response = HTTParty.get(customer_reviews_path(app_id), headers: authorization_headers)
  
  if response.code == 200
    @reviews = CustomerReviews.new(response['data'], 'Yoigo')
  else
    raise "Reviews download failed! #{response.code.to_s} #{response.message.to_s}"
  end
end

def get_sales_and_reports
  response = HTTParty.get(sales_path_absolute_url, headers: sales_headers)
  
  if response.code == 200
    @sales_and_reports_collection = SalesAndReportsCollection.new(response.body)
  else
    raise "Sales and reports download failed! #{response.code.to_s} #{response.message.to_s}"
  end
end

end
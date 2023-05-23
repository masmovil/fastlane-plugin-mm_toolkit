# frozen_string_literal: true

class SalesAndReports
  attr_reader :provider, :provider_country, :sku, :developer, :title, :version, :product_type_identifier, :units, :developer_proceeds, :begin_date,
    :end_date, :customer_currency, :country_code, :currency_of_proceeds, :apple_identifier, :customer_price, :promo_code, :parent_identifier, :subscription,
    :period, :category, :cmb, :device, :supported_platforms, :proceeds_reason, :preserved_pricing, :client, :order_type

  def initialize(provider, provider_country, sku, developer, title,
    version, product_type_identifier, units, developer_proceeds, begin_date,
    end_date, customer_currency, country_code, currency_of_proceeds, apple_identifier,
    customer_price, promo_code, parent_identifier, subscription, period,
    category, cmb, device, supported_platforms, proceeds_reason,
    preserved_pricing, client, order_type)
    @provider = provider
    @provider_country = provider_country
    @sku = sku
    @developer = developer
    @title = title
    @version = version
    @product_type_identifier = product_type_identifier
    @units = units
    @developer_proceeds = developer_proceeds
    @begin_date = begin_date
    @end_date = end_date
    @customer_currency = customer_currency
    @country_code = country_code
    @currency_of_proceeds = currency_of_proceeds
    @apple_identifier = apple_identifier
    @customer_price = customer_price
    @promo_code = promo_code
    @parent_identifier = parent_identifier
    @subscription = subscription
    @period = period
    @category = category
    @cmb = cmb
    @device = device
    @supported_platforms = supported_platforms
    @proceeds_reason = proceeds_reason
    @preserved_pricing = preserved_pricing
    @client = client
    @order_type = order_type
  end
end

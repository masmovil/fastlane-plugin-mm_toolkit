# frozen_string_literal: true

class AppStoreConnectAccount
  attr_reader :issuer_id, :key_id, :private_key_content, :vendor_number

  def initialize(issuer_id, key_id, private_key_content, vendor_number)
    @issuer_id = issuer_id
    @key_id = key_id
    @private_key_content = private_key_content
    @vendor_number = vendor_number
  end
end

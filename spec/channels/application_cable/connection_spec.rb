# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:uuid_regex) { /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/ }
  let(:invalid_authorization_header_value) { "Bearer: invalid-#{CHECK_PLEASE['remote_request_api_key']}" }
  let(:valid_authorization_header_value) { "Bearer: #{CHECK_PLEASE['remote_request_api_key']}" }

  it 'rejects a connection when no authorization header is given' do
    expect { connect '/cable' }.to have_rejected_connection
  end

  it 'rejects a connection when an invalid authorization header value is given' do
    expect {
      connect '/cable', headers: { 'Authorization' => invalid_authorization_header_value }
    }.to have_rejected_connection
  end

  it "successfully connects and assigns a uuid value to the connection's uuid field" do
    connect '/cable', headers: { 'Authorization' => valid_authorization_header_value }
    expect(connection.uuid).to match(uuid_regex)
  end
end

# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :uuid

    def connect
      authenticate! # reject connections that do not successfully authenticate
      self.uuid = SecureRandom.uuid # assign a random uuid value when a user connects
    end

    private

    def authenticate!
      return if request.authorization&.split(' ')&.at(1) == CHECK_PLEASE['remote_request_api_key']

      reject_unauthorized_connection
    end
  end
end

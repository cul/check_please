# frozen_string_literal: true

require 'rails_helper'

fixity_check_id = 1
endpoint = "/fixity_checks/#{fixity_check_id}"

RSpec.describe endpoint, type: :request do
  describe "GET #{endpoint}" do
    context 'when unauthenticated request' do
      it 'returns a 401 (unauthorized) status when no auth token is provided' do
        get endpoint
        expect(response.status).to eq(401)
      end

      it 'returns a 401 (unauthorized) status when an incorrect auth token is provided' do
        get endpoint, headers: { 'Authorization' => 'Token NOTVALID' }
        expect(response.status).to eq(401)
      end
    end

    context 'when authenticated request' do
      let(:job_identifier) { SecureRandom.uuid }
      let(:bucket_name) { 'cul-dlstor-digital-testing1' }
      let(:object_path) { 'test-909kb-file.jpg' }
      let(:checksum_algorithm_name) { 'sha256' }

      let(:example_content) { 'example' }
      let(:checksum_hexdigest) { Digest::SHA256.hexdigest(example_content) }
      let(:object_size) { example_content.bytesize }

      context 'when a resource exists at the requested path' do
        before do
          FactoryBot.create(
            :fixity_check,
            :success,
            id: fixity_check_id,
            job_identifier: job_identifier,
            bucket_name: bucket_name,
            object_path: object_path,
            checksum_algorithm_name: checksum_algorithm_name,
            checksum_hexdigest: checksum_hexdigest,
            object_size: object_size
          )
        end

        it 'returns a 200 (ok) status ' do
          get_with_auth endpoint
          expect(response.status).to eq(200)
        end

        it 'returns the expected response body' do
          get_with_auth endpoint
          expect(response.body).to be_json_eql(%(
            {
              "bucket_name": "#{bucket_name}",
              "checksum_algorithm_name": "#{checksum_algorithm_name}",
              "checksum_hexdigest": "#{checksum_hexdigest}", "error_message": null,
              "job_identifier": "#{job_identifier}",
              "object_path": "#{object_path}",
              "object_size": #{object_size},
              "status": "success"
            }
          ))
        end
      end
    end
  end
end

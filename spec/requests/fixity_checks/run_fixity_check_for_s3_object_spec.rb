# frozen_string_literal: true

require 'rails_helper'

endpoint = '/fixity_checks/run_fixity_check_for_s3_object'

RSpec.describe endpoint, type: :request do
  describe "POST #{endpoint}" do
    context 'when unauthenticated request' do
      it 'returns a 401 (unauthorized) status when no auth token is provided' do
        post endpoint
        expect(response.status).to eq(401)
      end

      it 'returns a 401 (unauthorized) status when an incorrect auth token is provided' do
        post endpoint, headers: { 'Authorization' => 'Token NOTVALID' }
        expect(response.status).to eq(401)
      end
    end

    context 'when authenticated request' do
      let(:bucket_name) { 'cul-dlstor-digital-testing1' }
      let(:object_path) { 'test-909kb-file.jpg' }
      let(:checksum_algorithm_name) { 'sha256' }

      let(:example_content) { 'example' }
      let(:checksum_hexdigest) { Digest::SHA256.hexdigest(example_content) }
      let(:object_size) { example_content.bytesize }

      let(:fixity_check_params) do
        {
          fixity_check: {
            bucket_name: bucket_name,
            object_path: object_path,
            checksum_algorithm_name: checksum_algorithm_name
          }
        }
      end

      context 'when valid params are given' do
        before do
          allow(CheckPlease::Aws::ObjectFixityChecker).to receive(:check).with(
            bucket_name,
            object_path,
            checksum_algorithm_name
          ).and_return([checksum_hexdigest, object_size])
        end

        it 'returns a 200 (ok) status ' do
          post_with_auth endpoint, params: fixity_check_params
          expect(response.status).to eq(200)
        end

        it 'returns the expected response body' do
          post_with_auth endpoint, params: fixity_check_params
          expect(response.body).to be_json_eql(%(
            {
              "bucket_name": "#{bucket_name}",
              "checksum_algorithm_name": "#{checksum_algorithm_name}",
              "checksum_hexdigest": "#{checksum_hexdigest}",
              "object_path": "#{object_path}",
              "object_size": #{object_size}
            }
          ))
        end
      end

      context 'when a required param is missing' do
        [:bucket_name, :object_path, :checksum_algorithm_name].each do |required_param|
          context "when required param #{required_param} is missing" do
            before do
              fixity_check_params[:fixity_check].delete(required_param)
              post_with_auth endpoint, params: fixity_check_params
            end

            it 'returns a 400 (bad request) status ' do
              expect(response.status).to eq(400)
            end

            it 'returns the expected error' do
              expect(response.body).to be_json_eql(%({
                "error_message" : "param is missing or the value is empty: #{required_param}",
                "bucket_name": null,
                "checksum_algorithm_name": null,
                "object_path": null
              }))
            end
          end
        end
      end

      context 'when an unsupported checksum algorithm is supplied' do
        let(:checksum_algorithm_name) { 'sha256-and-a-half' }

        before do
          post_with_auth endpoint, params: fixity_check_params
        end

        it 'returns a 400 (bad request) status' do
          expect(response.status).to eq(400)
        end

        it 'returns the expected error' do
          expect(response.body).to be_json_eql(%({
            "error_message" : "Unsupported checksum algorithm: #{checksum_algorithm_name}",
            "bucket_name": "#{bucket_name}",
            "checksum_algorithm_name": "#{checksum_algorithm_name}",
            "object_path": "#{object_path}"
          }))
        end
      end

      context 'when any StandardError is raised during processing' do
        let(:error_message) { 'oh no!' }

        before do
          allow(CheckPlease::Aws::ObjectFixityChecker).to receive(:check).and_raise(StandardError, error_message)
          post_with_auth endpoint, params: fixity_check_params
        end

        it 'returns a 400 (bad request) status' do
          expect(response.status).to eq(400)
        end

        it 'returns the expected error' do
          expect(response.body).to be_json_eql(%({
            "error_message" : "#{error_message}",
            "bucket_name": "#{bucket_name}",
            "checksum_algorithm_name": "#{checksum_algorithm_name}",
            "object_path": "#{object_path}"
          }))
        end
      end
    end
  end
end

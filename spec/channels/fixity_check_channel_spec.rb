# frozen_string_literal: true

# rubocop:disable RSpec/ExampleLength

require 'rails_helper'

RSpec.describe FixityCheckChannel, type: :channel do
  let(:connection_uuid) { 'ef8416ee-9a10-43e8-9e8a-a84465ef1dea' }
  let(:job_identifier) { 'great-job-identifier' }

  before do
    # This is a convenient way to create a connection with a specific, known uuid (rather than a random one)
    stub_connection(uuid: connection_uuid)
  end

  it 'does not connect to a stream if subscription job_identifier param is absent' do
    subscribe
    expect(subscription).to be_confirmed
    expect(subscription.streams.length).to eq(0)
  end

  context 'with a successful subscription' do
    before do
      subscribe(job_identifier: job_identifier)
    end

    it 'connects to the expected stream if subscription job_identifier param is present' do
      expect(subscription).to be_confirmed
      expect(subscription.streams.length).to eq(1)
      expect(subscription.streams).to include("CheckPlease:test:fixity_check:#{job_identifier}")
    end

    context 'when a client sends a run_fixity_check_for_s3_object message' do
      let(:bucket_name) { 'example-bucket' }
      let(:object_path) { 'path/to/object.png' }
      let(:checksum_algorithm_name) { 'sha256' }
      let(:file_content) { 'A' * 1024 }
      let(:checksum_hexdigest) { Digest::SHA256.hexdigest(file_content) }
      let(:object_size) { file_content.bytesize }
      let(:fixity_check) do
        FactoryBot.create(
          :fixity_check,
          job_identifier: job_identifier,
          bucket_name: bucket_name,
          object_path: object_path,
          checksum_algorithm_name: checksum_algorithm_name
        )
      end

      before do
        allow(CheckPlease::Aws::ObjectFixityChecker).to receive(:check).with(
          bucket_name,
          object_path,
          checksum_algorithm_name,
          on_chunk: Proc # any Proc
        ).and_return([checksum_hexdigest, object_size])
      end

      it  'initiates a checksum calculation, which queues a background job and '\
          'responds with a fixity_check_complete broadcast' do
        expect(AwsCheckFixityJob).to receive(:perform_later).with(
          FixityCheck.count + 1
        ).and_call_original

        expect {
          perform :run_fixity_check_for_s3_object,
                  job_identifier: job_identifier,
                  bucket_name: bucket_name,
                  object_path: object_path,
                  checksum_algorithm_name: checksum_algorithm_name
        }.to have_broadcasted_to("#{FixityCheckChannel::FIXITY_CHECK_STREAM_PREFIX}#{job_identifier}").with(
          {
            type: 'fixity_check_complete',
            data: {
              bucket_name: bucket_name, object_path: object_path,
              checksum_algorithm_name: checksum_algorithm_name,
              checksum_hexdigest: checksum_hexdigest, object_size: object_size
            }
          }.to_json
        )
      end
    end
  end
end

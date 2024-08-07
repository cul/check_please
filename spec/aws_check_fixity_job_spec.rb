# frozen_string_literal: true

# rubocop:disable RSpec/ExampleLength

require 'rails_helper'

describe AwsCheckFixityJob do
  let(:aws_check_fixity_job) { described_class.new }
  let(:job_identifier) { 'great-job' }
  let(:bucket_name) { 'example-bucket' }
  let(:object_path) { 'path/to/object.png' }
  let(:checksum_algorithm_name) { 'sha256' }
  let(:example_content) { 'example' }
  let(:checksum_hexdigest) { Digest::SHA256.hexdigest(example_content) }
  let(:object_size) { example_content.bytesize }
  let(:stream_name) { "#{FixityCheckChannel::FIXITY_CHECK_STREAM_PREFIX}#{job_identifier}" }
  let(:error_message) { 'oh no!' }

  describe '#perform' do
    it 'works as expected' do
      allow(CheckPlease::Aws::ObjectFixityChecker).to receive(:check).with(
        bucket_name,
        object_path,
        checksum_algorithm_name,
        on_chunk: Proc
      ).and_return([checksum_hexdigest, object_size])
      expect(aws_check_fixity_job).to receive(:broadcast_fixity_check_complete).with(
        stream_name,
        bucket_name,
        object_path,
        checksum_algorithm_name,
        checksum_hexdigest,
        object_size
      )
      aws_check_fixity_job.perform(job_identifier, bucket_name, object_path, checksum_algorithm_name)
    end

    it 'broadcasts a fixity check error message when an error occurs during processing' do
      allow(CheckPlease::Aws::ObjectFixityChecker).to receive(:check).and_raise(StandardError, error_message)

      expect(aws_check_fixity_job).to receive(:broadcast_fixity_check_error).with(
        stream_name,
        error_message,
        bucket_name,
        object_path,
        checksum_algorithm_name
      )
      aws_check_fixity_job.perform(job_identifier, bucket_name, object_path, checksum_algorithm_name)
    end
  end

  describe '#progress_report_lambda' do
    let(:chunk) { 'a chunk of content' }
    let(:bytes_read) { 12_345 }

    it 'broadcasts an Action Cable message at the expected interval' do
      progress_report_lambda = aws_check_fixity_job.progress_report_lambda(stream_name)
      expect(ActionCable.server).to receive(:broadcast).exactly(10).times
      (1..1000).each do |i|
        progress_report_lambda.call(chunk, bytes_read, i)
      end
    end
  end

  describe '#broadcast_fixity_check_complete' do
    it 'results in the expected broadcast' do
      expect(ActionCable.server).to receive(:broadcast).with(
        stream_name,
        {
          type: 'fixity_check_complete',
          data: {
            bucket_name: bucket_name, object_path: object_path,
            checksum_algorithm_name: checksum_algorithm_name,
            checksum_hexdigest: checksum_hexdigest, object_size: object_size
          }
        }.to_json
      )
      aws_check_fixity_job.broadcast_fixity_check_complete(
        stream_name, bucket_name, object_path, checksum_algorithm_name, checksum_hexdigest, object_size
      )
    end
  end

  describe '#broadcast_fixity_check_error' do
    it 'results in the expected broadcast' do
      expect(ActionCable.server).to receive(:broadcast).with(
        stream_name,
        {
          type: 'fixity_check_error',
          data: {
            error_message: error_message, bucket_name: bucket_name,
            object_path: object_path, checksum_algorithm_name: checksum_algorithm_name
          }
        }.to_json
      )
      aws_check_fixity_job.broadcast_fixity_check_error(
        stream_name, error_message, bucket_name, object_path, checksum_algorithm_name
      )
    end
  end
end

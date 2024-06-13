# frozen_string_literal: true

class AwsCheckFixityJob < ApplicationJob
  queue_as CheckPlease::Queues::CHECK_FIXITY

  def perform(job_identifier, bucket_name, object_path, checksum_algorithm_name)
    response_stream_name = "#{FixityCheckChannel::FIXITY_CHECK_STREAM_PREFIX}#{job_identifier}"

    checksum_hexdigest, object_size = CheckPlease::Aws::ObjectFixityChecker.check(
      bucket_name,
      object_path,
      checksum_algorithm_name,
      on_chunk: progress_report_lambda(response_stream_name)
    )

    # Broadcast message when job is complete
    broadcast_fixity_check_complete(
      response_stream_name, bucket_name, object_path, checksum_algorithm_name, checksum_hexdigest, object_size
    )
  rescue StandardError => e
    broadcast_fixity_check_error(response_stream_name, e.message, bucket_name, object_path, checksum_algorithm_name)
  end

  def broadcast_fixity_check_complete(
    response_stream_name, bucket_name, object_path, checksum_algorithm_name, checksum_hexdigest, object_size
  )
    ActionCable.server.broadcast(
      response_stream_name,
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

  def broadcast_fixity_check_error(
    response_stream_name, error_message, bucket_name, object_path, checksum_algorithm_name
  )
    ActionCable.server.broadcast(
      response_stream_name,
      {
        type: 'fixity_check_error',
        data: {
          error_message: error_message, bucket_name: bucket_name,
          object_path: object_path, checksum_algorithm_name: checksum_algorithm_name
        }
      }.to_json
    )
  end

  def progress_report_lambda(response_stream_name)
    lambda do |_chunk, _bytes_read, chunk_counter|
      return unless (chunk_counter % 100).zero?

      # We periodically broadcast a message to indicate that the processing is still happening.
      # This is so that a client can check whether a job has stalled.
      ActionCable.server.broadcast(
        response_stream_name,
        { type: 'fixity_check_in_progress' }.to_json
      )
    end
  end
end

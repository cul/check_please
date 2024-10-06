# frozen_string_literal: true

class AwsCheckFixityJob < ApplicationJob
  queue_as CheckPlease::Queues::CHECK_FIXITY

  def perform(fixity_check_id)
    fixity_check = FixityCheck.find(fixity_check_id)
    response_stream_name = "#{FixityCheckChannel::FIXITY_CHECK_STREAM_PREFIX}#{fixity_check.job_identifier}"

    # Begin calculating checksum and file size
    fixity_check.in_progress!
    checksum_hexdigest, object_size = CheckPlease::Aws::ObjectFixityChecker.check(
      fixity_check.bucket_name,
      fixity_check.object_path,
      fixity_check.checksum_algorithm_name,
      on_chunk: progress_report_lambda(fixity_check, response_stream_name)
    )

    fixity_check.update!(
      checksum_hexdigest: checksum_hexdigest,
      object_size: object_size,
      status: :success
    )

    # Broadcast message when job is complete
    broadcast_fixity_check_complete(
      response_stream_name, fixity_check.bucket_name, fixity_check.object_path,
      fixity_check.checksum_algorithm_name, checksum_hexdigest, object_size
    )
  rescue StandardError => e
    fixity_check.update!(
      checksum_hexdigest: checksum_hexdigest,
      object_size: object_size,
      status: :failure,
      error_message: "An unexpected error occurred: #{e.class.name} -> #{e.message}"
    )
    broadcast_fixity_check_error(
      response_stream_name, e.message, fixity_check.bucket_name,
      fixity_check.object_path, fixity_check.checksum_algorithm_name
    )
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

  def progress_report_lambda(fixity_check, response_stream_name)
    lambda do |_chunk, _bytes_read, chunk_counter|
      # Only provide an update once per 1000 chunks processed
      return unless (chunk_counter % 1000).zero?

      # Update the updated_at attribute for this FixityCheck record
      fixity_check.touch # rubocop:disable Rails/SkipsModelValidations

      # We periodically broadcast a message to indicate that the processing is still happening.
      # This is so that a client can check whether a job has stalled.
      ActionCable.server.broadcast(
        response_stream_name,
        { type: 'fixity_check_in_progress' }.to_json
      )
    end
  end
end

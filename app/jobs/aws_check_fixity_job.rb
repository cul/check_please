# frozen_string_literal: true

class AwsCheckFixityJob < ApplicationJob
  queue_as CheckPlease::Queues::CHECK_FIXITY

  PROGRESS_UPDATE_FREQUENCY = 2.seconds

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
    lambda do |_chunk, _bytes_read, _chunk_counter|
      # We don't want to handle progress updates on every chunk, since this would be way too frequent.
      time_since_last_update = Time.current - fixity_check.updated_at
      return if time_since_last_update < PROGRESS_UPDATE_FREQUENCY

      # Provide progress updates for any processes that might be monitoring this job
      run_progress_update(fixity_check, response_stream_name)
    end
  end

  def run_progress_update(fixity_check, response_stream_name)
    # 1) Update the updated_at attribute for this FixityCheck record
    fixity_check.touch # rubocop:disable Rails/SkipsModelValidations

    # 2) Broadcast an ActionCable message to indicate that the processing is still happening.
    # Websocket clients use this information to check whether a job has stalled.
    ActionCable.server.broadcast(
      response_stream_name,
      { type: 'fixity_check_in_progress' }.to_json
    )
  end
end

# frozen_string_literal: true

class FixityCheckChannel < ApplicationCable::Channel
  FIXITY_CHECK_STREAM_PREFIX = "#{CHECK_PLEASE['action_cable_stream_prefix']}fixity_check:".freeze

  # A websocket client subscribes by sending this message:
  # {
  #     "command" =>  "subscribe",
  #     "identifier" =>  { "channel" => "FixityCheckChannel", "job_identifier" => "cool-job-id1" }.to_json
  # }
  def subscribed
    return if params[:job_identifier].blank?

    stream_name = "#{FIXITY_CHECK_STREAM_PREFIX}#{params[:job_identifier]}"
    Rails.logger.debug "A client has started streaming from: #{stream_name}"
    stream_from stream_name
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    return if params[:job_identifier].blank?

    stream_name = "#{FIXITY_CHECK_STREAM_PREFIX}#{params[:job_identifier]}"
    Rails.logger.debug "A client has stopped streaming from: #{stream_name}"
    stop_stream_from stream_name
  end

  # A websocket client runs this command by sending this message:
  # {
  #     "command" =>  "run_fixity_check_for_s3_object",
  #     "identifier" =>  { "channel" => "FixityCheckChannel", "job_identifier" => "cool-job-id1" }.to_json,
  #     "data" =>  {
  #                   "action" =>  "run_fixity_check_for_s3_object", "bucket_name" =>  "some-bucket",
  #                   "object_path" =>  "path/to/object.png", "checksum_algorithm_name" =>  "sha256"
  #                 }.to_json
  # }
  def run_fixity_check_for_s3_object(data)
    Rails.logger.debug("run_fixity_check_for_s3_object action received with job_identifier: #{params[:job_identifier]}")
    job_identifier = params[:job_identifier]
    bucket_name = data['bucket_name']
    object_path = data['object_path']
    checksum_algorithm_name = data['checksum_algorithm_name']

    fixity_check = FixityCheck.create!(
      job_identifier: job_identifier,
      bucket_name: bucket_name,
      object_path: object_path,
      checksum_algorithm_name: checksum_algorithm_name
    )
    AwsCheckFixityJob.perform_later(fixity_check.id)
  end
end

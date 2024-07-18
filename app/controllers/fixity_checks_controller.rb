# frozen_string_literal: true

class FixityChecksController < ApiController
  before_action :authenticate_request_token

  # POST /fixity_checks/run_fixity_check_for_s3_object
  def run_fixity_check_for_s3_object
    bucket_name = fixity_check_params['bucket_name']
    object_path = fixity_check_params['object_path']
    checksum_algorithm_name = fixity_check_params['checksum_algorithm_name']

    checksum_hexdigest, object_size = CheckPlease::Aws::ObjectFixityChecker.check(
      bucket_name, object_path, checksum_algorithm_name
    )

    render plain: {
      bucket_name: bucket_name, object_path: object_path, checksum_algorithm_name: checksum_algorithm_name,
      checksum_hexdigest: checksum_hexdigest, object_size: object_size
    }.to_json
  rescue StandardError => e
    render plain: {
      error_message: e.message,
      bucket_name: bucket_name, object_path: object_path, checksum_algorithm_name: checksum_algorithm_name
    }.to_json, status: :bad_request
  end

  private

  def fixity_check_response(bucket_name, object_path, checksum_algorithm_name, checksum_hexdigest, object_size)
    run_fixity_check_for_s3_object
    {
      bucket_name: bucket_name, object_path: object_path, checksum_algorithm_name: checksum_algorithm_name,
      checksum_hexdigest: checksum_hexdigest, object_size: object_size
    }.to_json
  end

  def fixity_check_params
    params.require(:fixity_check).tap do |fixity_check_params|
      fixity_check_params.require(:bucket_name)
      fixity_check_params.require(:object_path)
      fixity_check_params.require(:checksum_algorithm_name)
    end
  end
end

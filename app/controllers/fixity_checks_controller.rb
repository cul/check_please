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

    render json: {
      bucket_name: bucket_name, object_path: object_path, checksum_algorithm_name: checksum_algorithm_name,
      checksum_hexdigest: checksum_hexdigest, object_size: object_size
    }
  rescue StandardError => e
    render json: {
      error_message: e.message,
      bucket_name: bucket_name, object_path: object_path, checksum_algorithm_name: checksum_algorithm_name
    }, status: :bad_request
  end

  def create
    bucket_name = fixity_check_params['bucket_name']
    object_path = fixity_check_params['object_path']
    checksum_algorithm_name = fixity_check_params['checksum_algorithm_name']
    fixity_check = FixityCheck.create!(
      # User does not need to supply a job_identifier param when using the create endpoint.
      # We'll just use a ranom UUID here.
      job_identifier: SecureRandom.uuid,
      bucket_name: bucket_name,
      object_path: object_path,
      checksum_algorithm_name: checksum_algorithm_name
    )
    AwsCheckFixityJob.perform_later(fixity_check.id)
    render json: fixity_check
  rescue StandardError => e
    render json: {
      error_message: e.message
    }, status: :bad_request
  end

  # GET /fixity_checks/1
  def show
    render json: FixityCheck.find(params[:id])
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

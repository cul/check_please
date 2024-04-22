# frozen_string_literal: true

# Load CHECK_PLEASE config
CHECK_PLEASE = Rails.application.config_for(:check_please).deep_symbolize_keys

# Save app version in APP_VERSION constant
APP_VERSION = File.read(Rails.root.join('VERSION')).strip

Rails.application.config.active_job.queue_adapter = :inline if CHECK_PLEASE['run_queued_jobs_inline']

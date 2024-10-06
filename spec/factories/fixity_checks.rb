# frozen_string_literal: true

FactoryBot.define do
  factory :fixity_check do
    job_identifier { SecureRandom.uuid }
    bucket_name { 'sample_bucket' }
    object_path { 'some/object/path' }
    checksum_algorithm_name { 'sha256' }

    trait :in_progress do
      status { 'in_progress' }
    end

    trait :failure do
      status { 'failure' }
      error_message { 'An error occurred and this is the message associated with it.' }
    end

    trait :success do
      status { 'success' }
      example_content = 'example'
      checksum_hexdigest { Digest::SHA256.hexdigest(example_content) }
      object_size { example_content.bytesize }
    end
  end
end

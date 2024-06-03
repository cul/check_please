# frozen_string_literal: true

module CheckPlease::Aws::ObjectFixityChecker
  def self.digester_for_checksum_algorithm!(checksum_algorithm_name)
    case checksum_algorithm_name
    when 'sha256'
      Digest::SHA256.new
    when 'sha512'
      Digest::SHA512.new
    when 'md5'
      Digest::MD5.new
    when 'crc32c'
      Digest::CRC32c.new
    else
      raise ArgumentError, "Unsupported checksum algorithm: #{checksum_algorithm_name}"
    end
  end

  # Checks the specified object and returns
  # @param bucket_name [String] The name of the S3 bucket
  # @param object_path [String] The object path in the S3 bucket
  # @param checksum_algorithm_name [String] A checksum algorithm name.
  #                                         Allowed values include: sha256, sha512, md5, crc32c
  # @param on_chunk [lambda] A lambda that is called once per data chunk read, during the fixity check.
  # @return [Array] An with two elements, the first being a hex digest of the object's bytes and the second
  #                 being the object size in bytes.
  def self.check(bucket_name, object_path, checksum_algorithm_name, on_chunk: nil)
    digester_for_checksum_algorithm = digester_for_checksum_algorithm!(checksum_algorithm_name)
    bytes_read = 0
    chunk_counter = 0

    obj = S3_CLIENT.get_object({ bucket: bucket_name, key: object_path }) do |chunk, _headers|
      digester_for_checksum_algorithm.update(chunk)
      bytes_read += chunk.bytesize
      chunk_counter += 1
      on_chunk&.call(chunk, bytes_read, chunk_counter)
    end

    # The bytes_read sum should equal the AWS-reported obj.content_length,
    # but we'll add a check here just in case there's ever a mismatch.
    verify_read_byte_count!(bytes_read, obj.content_length)

    [digester_for_checksum_algorithm.hexdigest, bytes_read]
  rescue Aws::S3::Errors::NoSuchKey
    raise CheckPlease::Exceptions::ObjectNotFoundError,
          "Could not find AWS object: bucket=#{bucket_name}, path=#{object_path}"
  end

  def self.verify_read_byte_count!(bytes_read, expected_total_byte_count)
    return if bytes_read == expected_total_byte_count

    raise CheckPlease::Exceptions::ReportedFileSizeMismatchError,
          "S3 reported an object size of #{expected_total_byte_count} bytes, but we only received #{bytes_read} bytes"
  end
end

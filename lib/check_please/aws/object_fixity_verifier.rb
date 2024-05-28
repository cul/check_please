# frozen_string_literal: true

module CheckPlease::Aws::ObjectFixityVerifier
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

  def self.verify(bucket_name, object_path, checksum_algorithm_name, print_memory_stats: false)
    digester_for_checksum_algorithm = digester_for_checksum_algorithm!(checksum_algorithm_name)
    bytes_read = 0
    memory_monitoring_counter = 0

    obj = S3_CLIENT.get_object({ bucket: bucket_name, key: object_path }) do |chunk, _headers|
      digester_for_checksum_algorithm.update(chunk)
      bytes_read += chunk.bytesize

      memory_monitoring_counter += 1
      collect_and_print_memory_stats(bytes_read) if print_memory_stats && (memory_monitoring_counter % 100).zero?
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

  def self.collect_and_print_memory_stats(bytes_read)
    pid, size = `ps ax -o pid,rss | grep -E "^[[:space:]]*#{$PROCESS_ID}"`.strip.split.map(&:to_i)
    puts "Read: #{bytes_read / 1.megabyte} MB. Memory usage for pid #{pid}: #{size.to_f / 1.kilobyte} MB." # rubocop:disable Rails/Output
  end
end

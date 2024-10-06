BUFFER_SIZE = 5.megabytes

memory_stat_lambda = lambda { |_chunk, bytes_read, chunk_counter|
  return unless (chunk_counter % 100).zero?
  pid, size = `ps ax -o pid,rss | grep -E "^[[:space:]]*#{$PROCESS_ID}"`.strip.split.map(&:to_i)
  puts "Read: #{bytes_read / 1.megabyte} MB. Memory usage for pid #{pid}: #{size.to_f / 1.kilobyte} MB." # rubocop:disable Rails/Output
}

namespace :check_please do
  namespace :verification do
    desc 'Verify the checksum for the file at the given bucket_name and object_path'
    task verify_s3_object: :environment do
      bucket_name = ENV['bucket_name']
      object_path = ENV['object_path']
      checksum_algorithm_name = ENV['checksum_algorithm_name']
      print_memory_stats = ENV['print_memory_stats'] == 'true'

      checksum, object_size = CheckPlease::Aws::ObjectFixityChecker.check(
        bucket_name,
        object_path,
        checksum_algorithm_name,
        on_chunk: print_memory_stats ? memory_stat_lambda : nil
      )

      puts "#{bucket_name}: #{object_path}"
      puts "#{checksum_algorithm_name} checksum is: #{checksum}"
      puts "object_size is: #{object_size}"
    end
  end
end

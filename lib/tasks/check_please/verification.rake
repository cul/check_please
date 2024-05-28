BUFFER_SIZE = 5.megabytes

namespace :check_please do
  namespace :verification do
    desc 'Verify the checksum for the file at the given bucket_name and object_path'
    task verify_s3_object: :environment do
      bucket_name = ENV['bucket_name']
      object_path = ENV['object_path']
      checksum_algorithm_name = ENV['checksum_algorithm_name']
      print_memory_stats = ENV['print_memory_stats'] == 'true'

      checksum, object_size = CheckPlease::Aws::ObjectFixityVerifier.verify(
        bucket_name,
        object_path,
        checksum_algorithm_name,
        print_memory_stats: print_memory_stats
      )
      puts "#{bucket_name}: #{object_path}"
      puts "#{checksum_algorithm_name} checksum is: #{checksum}"
      puts "object_size is: #{object_size}"
    end
  end
end

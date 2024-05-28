# frozen_string_literal: true

require 'rails_helper'

describe CheckPlease::Aws::ObjectFixityVerifier do
  describe '.digester_for_checksum_algorithm' do
    {
      'sha256' => Digest::SHA256,
      'sha512' => Digest::SHA512,
      'md5' => Digest::MD5,
      'crc32c' => Digest::CRC32c
    }.each do |checksum_algorithm_name, digester_class|
      it "returns a #{digester_class.name} instance when the string \"#{checksum_algorithm_name}\" is given" do
        expect(described_class.digester_for_checksum_algorithm!(checksum_algorithm_name)).to be_a(digester_class)
      end
    end

    it 'raises an exception when an unhandled checksum algorithm name is provided' do
      expect { described_class.digester_for_checksum_algorithm!('nope') }.to raise_error(ArgumentError)
    end
  end

  describe '.verify' do
    let(:bucket_name) { 'example-bucket' }
    let(:object_path) { 'a/b/c.txt' }
    let(:checksum_algorithm_name) { 'sha256' }
    let(:print_memory_stats) { false }
    let(:chunk1) { 'aaaaa' }
    let(:chunk2) { 'bbbbb' }
    let(:chunk3) { 'c' }
    let(:expected_content_length) { chunk1.bytesize + chunk2.bytesize + chunk3.bytesize }
    let(:get_object_response) do
      headers = double(Seahorse::Client::Response)
      allow(headers).to receive(:content_length).and_return(expected_content_length)
      headers
    end
    let(:get_object_response_headers) { double(Seahorse::Client::Http::Headers) }
    let(:expected_sha256_checksum_hexdigest) { Digest::SHA256.hexdigest(chunk1 + chunk2 + chunk3) }

    before do
      allow(S3_CLIENT).to receive(:get_object).with(
        { bucket: bucket_name, key: object_path }
      ).and_return(get_object_response).and_yield(
        chunk1, get_object_response_headers
      ).and_yield(
        chunk2, get_object_response_headers
      ).and_yield(
        chunk3, get_object_response_headers
      )
    end

    it 'returns the expected value' do
      expect(
        described_class.verify(
          bucket_name, object_path, checksum_algorithm_name, print_memory_stats: print_memory_stats
        )
      ).to eq([expected_sha256_checksum_hexdigest, expected_content_length])
    end

    context 'when expected content length does not equal the number of bytes read' do
      let(:expected_content_length) { 1 }

      it 'raises an exception' do
        expect {
          described_class.verify(
            bucket_name, object_path, checksum_algorithm_name, print_memory_stats: print_memory_stats
          )
        }.to raise_error(
          CheckPlease::Exceptions::ReportedFileSizeMismatchError
        )
      end
    end
  end
end

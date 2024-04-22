# frozen_string_literal: true

require 'rails_helper'

describe CheckPlease::Utils::HexUtils do
  describe '.hex_to_bin' do
    it 'converts hex data to a binary string as expected' do
      expect(described_class.hex_to_bin('4d7953514c')).to eql 'MySQL'.b
    end
  end

  describe '.bin_to_hex' do
    it 'converts a binary string to hex as expected' do
      expect(described_class.bin_to_hex('MySQL')).to eql '4d7953514c'
    end
  end

  describe 'round trip conversions' do
    let(:hex_string) { '7b8ff55800b55c0b3d53d2c81067225b115edfda4572a9253581a31efd231d94' }

    it 'works as expected' do
      expect(described_class.bin_to_hex(described_class.hex_to_bin(hex_string))).to eql(hex_string)
    end
  end
end

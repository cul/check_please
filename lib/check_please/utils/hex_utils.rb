# frozen_string_literal: true

module CheckPlease::Utils::HexUtils
  # Converts the given hex string to a binary string
  def self.hex_to_bin(hex_string)
    return nil unless /^([0-9a-fA-F]{2})*$/.match?(hex_string)

    hex_string.scan(/../).map(&:hex).pack('c*')
  end

  def self.bin_to_hex(binary_string)
    binary_string.unpack1('H*')
  end
end

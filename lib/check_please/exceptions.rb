# frozen_string_literal: true

module CheckPlease::Exceptions
  class CheckPleaseError < StandardError; end

  class ObjectNotFoundError < CheckPleaseError; end
  class ReportedFileSizeMismatchError < CheckPleaseError; end
end

# frozen_string_literal: true

class FixityCheck < ApplicationRecord
  enum status: { pending: 0, in_progress: 1, success: 2, failure: 3 }
end

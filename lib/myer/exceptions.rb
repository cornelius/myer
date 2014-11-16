module Myer
  class Error < StandardError; end

  class CmdFailed < Error; end
  class DecryptionFailed < Error; end
end


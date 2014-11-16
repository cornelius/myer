class Crypto

  attr_accessor :passphrase

  def generate_passphrase
    `gpg --armor --gen-random 1 16`.chomp
  end

  def call_cmd(cmd, input)
    output = nil
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      stdin.puts(input)
      stdin.close
      output = stdout.read

      if !wait_thr.value.success?
        raise Myer::CmdFailed.new(stderr.read)
      end
    end
    output
  end

  def encrypt(plaintext)
    cmd = "gpg --batch --armor --passphrase '#{passphrase}' --symmetric"
    begin
      return call_cmd(cmd, plaintext)
    rescue Myer::CmdFailed => e
      raise "Encryption failed: #{e}"
    end
  end

  def decrypt(ciphertext)
    cmd = "gpg --batch --passphrase '#{passphrase}' --decrypt"
    begin
      return call_cmd(cmd, ciphertext).chomp
    rescue Myer::CmdFailed => e
      raise Myer::DecryptionFailed.new("Decryption failed: #{e}")
    end
  end
end

class Crypto

  attr_accessor :passphrase

  def generate_passphrase
    `gpg --armor --gen-random 1 16`.chomp
  end

  def encrypt(plaintext)
    cmd = "gpg --batch --armor --passphrase #{passphrase} --symmetric"
    ciphertext = nil
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      stdin.puts(plaintext)
      stdin.close
      ciphertext = stdout.read

      if !wait_thr.value.success?
        raise "Encryption failed #{stderr.read}"
      end
    end
    ciphertext
  end

  def decrypt(ciphertext)
    cmd = "gpg --batch --passphrase #{passphrase} --decrypt"
    plaintext = nil
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      stdin.puts(ciphertext)
      stdin.close
      plaintext = stdout.read

      if !wait_thr.value.success?
        raise "Decryption failed: #{stderr.read}"
      end
    end
    plaintext.chomp
  end
end

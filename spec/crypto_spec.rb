require_relative "spec_helper"

describe Crypto do
  before(:each) do
    @crypto = Crypto.new
    @crypto.passphrase = "aOfZ+F6TcorXRFTK"
  end

  it "generates passphrase" do
    passphrase = @crypto.generate_passphrase

    expect(passphrase.length).to be > 16
  end

  it "encrypts and decrypts" do
    encrypted = @crypto.encrypt("some data")

    expect(encrypted).to match /PGP/

    decrypted = @crypto.decrypt(encrypted)

    expect(decrypted).to eq "some data"
  end

  it "doesn't decrypt with wrong passphrase" do
    encrypted = @crypto.encrypt("some data")

    expect(encrypted).to match /PGP/

    @crypto.passphrase = "wrong"

    expect {
      @crypto.decrypt(encrypted)
    }.to raise_error
  end
end

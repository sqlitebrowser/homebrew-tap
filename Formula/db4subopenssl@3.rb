class Db4subopensslAT3 < Formula
  desc "Cryptography and SSL/TLS Toolkit"
  homepage "https://openssl.org/"
  version "3.2.1"
  url "https://www.openssl.org/source/openssl-#{version}.tar.gz"
  mirror "https://www.mirrorservice.org/sites/ftp.openssl.org/source/openssl-#{version}.tar.gz"
  mirror "https://www.openssl.org/source/old/3.2/openssl-#{version}.tar.gz"
  mirror "https://www.mirrorservice.org/sites/ftp.openssl.org/source/old/3.2/openssl-#{version}.tar.gz"
  mirror "http://www.mirrorservice.org/sites/ftp.openssl.org/source/openssl-#{version}.tar.gz"
  mirror "http://www.mirrorservice.org/sites/ftp.openssl.org/source/old/3.2/openssl-#{version}.tar.gz"
  sha256 "83c7329fe52c850677d75e5d0b0ca245309b97e8ecbcfdc1dfdc4ab9fac35b39"
  license "Apache-2.0"
  env :std

  bottle do
    root_url "https://nightlies.sqlitebrowser.org/homebrew_bottles"
    rebuild 1
    sha256 arm64_sonoma: "d6d22ec74a8e2e303e982f744a752d765e5a79fafe57a389f3d46b415c5d3643"
  end
  
  livecheck do
    url "https://www.openssl.org/source/"
    regex(/href=.*?openssl[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end
  keg_only "not intended for general use"

  depends_on arch: :arm64
  depends_on "ca-certificates"

  # SSLv2 died with 1.1.0, so no-ssl2 no longer required.
  # SSLv3 & zlib are off by default with 1.1.0 but this may not
  # be obvious to everyone, so explicitly state it for now to
  # help debug inevitable breakage.
  def configure_args
    %W[
      darwin64-arm64-cc
      enable-ec_nistp_64_gcc_128
      --prefix=#{prefix}
      --openssldir=#{openssldir}
      --libdir=#{lib}
      -shared
      no-ssl3
      no-ssl3-method
      no-zlib
    ]
  end

  def install
    # This could interfere with how we expect OpenSSL to build.
    ENV.delete("OPENSSL_LOCAL_CONFIG_DIR")

    # This ensures where Homebrew's Perl is needed the Cellar path isn't
    # hardcoded into OpenSSL's scripts, causing them to break every Perl update.
    # Whilst our env points to opt_bin, by default OpenSSL resolves the symlink.
    ENV["PERL"] = Formula["perl"].opt_bin/"perl" if which("perl") == Formula["perl"].opt_bin/"perl"

    openssldir.mkpath
    system "perl", "./Configure", *configure_args
    system "make"
    system "make", "install", "MANDIR=#{man}", "MANSUFFIX=ssl"
    system "make", "test"
  end

  def openssldir
    etc/"db4subopenssl@3"
  end

  def post_install
    rm_f openssldir/"cert.pem"
    openssldir.install_symlink Formula["ca-certificates"].pkgetc/"cert.pem"
  end

  def caveats
    <<~EOS
      A CA file has been bootstrapped using certificates from the system
      keychain. To add additional certificates, place .pem files in
        #{openssldir}/certs

      and run
        #{opt_bin}/c_rehash
    EOS
  end

  test do
    # Make sure the necessary .cnf file exists, otherwise OpenSSL gets moody.
    assert_predicate pkgetc/"openssl.cnf", :exist?,
            "OpenSSL requires the .cnf file for some functionality"

    # Check OpenSSL itself functions as expected.
    (testpath/"testfile.txt").write("This is a test file")
    expected_checksum = "e2d0fe1585a63ec6009c8016ff8dda8b17719a637405a4e23c0ff81339148249"
    system bin/"openssl", "dgst", "-sha256", "-out", "checksum.txt", "testfile.txt"
    open("checksum.txt") do |f|
      checksum = f.read(100).split("=").last.strip
      assert_equal checksum, expected_checksum
    end
  end
end

class SqlbOpensslAT3 < Formula
  desc "Cryptography and SSL/TLS Toolkit"
  homepage "https://openssl.org/"
  url "https://github.com/openssl/openssl/releases/download/openssl-3.4.1/openssl-3.4.1.tar.gz"
  # version "3.4.1"
  sha256 "002a2d6b30b58bf4bea46c43bdd96365aaf8daa6c428782aa4feee06da197df3"
  license "Apache-2.0"

  livecheck do
    url "https://www.openssl.org/source/"
    regex(/href=.*?openssl[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://github.com/lucydodo/homebrew-tap/releases/download/sqlb-openssl@3-3.4.1"
    sha256 arm64_sonoma: "6da840dda45af0f56f1f2de196ac34617cb16df15b1db2dedaf8661efac52820"
  end

  keg_only :shadowed_by_macos, "macOS provides LibreSSL"

  depends_on arch: :arm64
  depends_on "ca-certificates"

  # SSLv2 died with 1.1.0, so no-ssl2 no longer required.
  # SSLv3 & zlib are off by default with 1.1.0 but this may not
  # be obvious to everyone, so explicitly state it for now to
  # help debug inevitable breakage.
  def configure_args
    %w[
      enable-ec_nistp_64_gcc_128
      no-asm
      no-ssl3
      no-ssl3-method
      no-zlib
    ]
  end

  def install
    # Determine the minimum macOS version.
    # Match the required version of the DB Browser for SQLite app.
    ENV["MACOSX_DEPLOYMENT_TARGET"] = "10.13"
    ENV.append "CPPFLAGS", "-mmacosx-version-min=10.13"
    ENV.append "LDFLAGS", "-mmacosx-version-min=10.13"

    # This could interfere with how we expect OpenSSL to build.
    ENV.delete("OPENSSL_LOCAL_CONFIG_DIR")

    # This ensures where Homebrew's Perl is needed the Cellar path isn't
    # hardcoded into OpenSSL's scripts, causing them to break every Perl update.
    # Whilst our env points to opt_bin, by default OpenSSL resolves the symlink.
    ENV["PERL"] = Formula["perl"].opt_bin/"perl" if which("perl") == Formula["perl"].opt_bin/"perl"

    arch_args = []
    arch_args << "darwin64-x86_64-cc"
    arch_args += %W[--prefix=#{prefix}/darwin64-x86_64-cc]
    arch_args += %W[--openssldir=#{openssldir}/darwin64-x86_64-cc]
    arch_args << "--libdir=#{prefix}/darwin64-x86_64-cc/lib"
    ENV.append "CFLAGS", "-arch x86_64"

    system "perl", "./Configure", *(configure_args + arch_args)
    system "arch", "-x86_64", "make"
    system "make", "install", "MANDIR=#{prefix}/darwin64-x86_64-cc/share/man", "MANSUFFIX=ssl"
    # AF_ALG support isn't always enabled (e.g. some containers), which breaks the tests.
    # AF_ALG is a kernel feature and failures are unlikely to be issues with the formula.
    # system "CFLAGS=\"-arch x86_64\" arch -x86_64 make test TESTS=-test_afalg"

    arch_args = []
    arch_args << "darwin64-arm64-cc"
    arch_args += %W[--prefix=#{prefix} --openssldir=#{openssldir} --libdir=lib]

    openssldir.mkpath
    system "make", "clean"
    system "perl", "./Configure", *(configure_args + arch_args)
    system "make"
    system "make", "install", "MANDIR=#{man}", "MANSUFFIX=ssl"
    # # AF_ALG support isn't always enabled (e.g. some containers), which breaks the tests.
    # # AF_ALG is a kernel feature and failures are unlikely to be issues with the formula.
    # system "make", "test", "TESTS=-test_afalg"

    mv "#{lib}/libcrypto.3.dylib", "#{lib}/libcrypto.3-arm64.dylib"
    dylib_arm64 = MachO::MachOFile.new("#{lib}/libcrypto.3-arm64.dylib")
    dylib_x86_64 = MachO::MachOFile.new("#{prefix}/darwin64-x86_64-cc/lib/libcrypto.3.dylib")
    fat = MachO::FatFile.new_from_machos(dylib_arm64, dylib_x86_64)
    fat.write("#{lib}/libcrypto.3.dylib")

    rm "#{lib}/libcrypto.dylib"
    rm_r "#{prefix}/darwin64-x86_64-cc/bin"
    rm_r "#{prefix}/darwin64-x86_64-cc/lib"
    ln_s "#{lib}/libcrypto.3.dylib", "#{lib}/libcrypto.dylib"
  end

  def openssldir
    etc/"sqlb-openssl@3"
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
    assert_path_exists pkgetc/"openssl.cnf", "OpenSSL requires the .cnf file for some functionality"

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

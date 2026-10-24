class SqlbIcu4c < Formula
  desc "C/C++ and Java libraries for Unicode and globalization"
  homepage "https://icu.unicode.org/home"
  url "https://github.com/unicode-org/icu/releases/download/release-78.3/icu4c-78.3-sources.tgz"
  # version "78.3"
  sha256 "3a2e7a47604ba702f345878308e6fefeca612ee895cf4a5f222e7955fabfe0c0"
  license "Unicode-3.0"

  livecheck do
    url :stable
    regex(/^release[._-]v?(78(?:[.-]\d+)+)$/i)
    strategy :git do |tags, regex|
      tags.filter_map { |tag| tag[regex, 1]&.tr("-", ".") }
    end
  end

  keg_only :shadowed_by_macos, "macOS provides libicucore.dylib (but nothing else)"

  depends_on arch: :arm64

  deny_network_access!

  def install
    # Determine the minimum macOS version.
    # Match the required version of the DB Browser for SQLite app.
    ENV["MACOSX_DEPLOYMENT_TARGET"] = "10.13"
    ENV.append "CPPFLAGS", "-mmacosx-version-min=10.13"
    ENV.append "LDFLAGS", "-mmacosx-version-min=10.13"

    args = %w[
      --disable-samples
      --disable-shared
      --disable-tests
      --enable-static
      --with-data-packaging=static
      --with-library-bits=64
    ]

    ENV.permit_arch_flags
    ENV.append "CFLAGS", "-arch x86_64"
    ENV.append "CXXFLAGS", "-arch x86_64"
    ENV.append "LDFLAGS", "-arch x86_64"

    mkdir "build-x86_64" do
      system "arch", "-x86_64", "../source/configure", *args,
             *std_configure_args(prefix: "#{buildpath}/darwin64-x86_64-cc")
      system "arch", "-x86_64", "make"
      system "arch", "-x86_64", "make", "install"
    end

    ENV.delete("CFLAGS")
    ENV.delete("CXXFLAGS")
    ENV.remove "LDFLAGS", "-arch x86_64"

    mkdir "build-arm64" do
      system "../source/configure", *args, *std_configure_args
      system "make"
      system "make", "install"
    end

    # ruby-macho cannot be used here because it only handles Mach-O files, not `ar` archives.
    lib.glob("*.a").each do |library|
      system "/usr/bin/lipo", "-create", library, "#{buildpath}/darwin64-x86_64-cc/lib/#{library.basename}",
             "-output", "#{buildpath}/#{library.basename}"
      mv "#{buildpath}/#{library.basename}", library
    end

    inreplace [bin/"icu-config", *lib.glob("pkgconfig/icu-*.pc")], prefix, opt_prefix
  end

  test do
    archs = shell_output("lipo -archs #{lib}/libicuuc.a").split
    assert_equal %w[arm64 x86_64], archs.sort

    if File.exist? "/usr/share/dict/words"
      system bin/"gendict", "--uchars", "/usr/share/dict/words", "dict"
    else
      (testpath/"hello").write "hello\nworld\n"
      system bin/"gendict", "--uchars", "hello", "dict"
    end
  end
end

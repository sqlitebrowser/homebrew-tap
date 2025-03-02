class SqlbSqlcipher < Formula
  desc "SQLite extension providing 256-bit AES encryption"
  homepage "https://www.zetetic.net/sqlcipher/"
  url "https://github.com/sqlcipher/sqlcipher/archive/refs/tags/v4.6.1.tar.gz"
  # version "4.6.1"
  sha256 "d8f9afcbc2f4b55e316ca4ada4425daf3d0b4aab25f45e11a802ae422b9f53a3"
  license "BSD-3-Clause"
  head "https://github.com/sqlcipher/sqlcipher.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/lucydodo/homebrew-tap/releases/download/sqlb-sqlcipher-4.6.1"
    sha256 cellar: :any, arm64_sonoma: "1c3b07faf269425e957a21ce0835e00339a4442d9533e89f7e0781e449804da8"
  end

  depends_on arch: :arm64
  depends_on "sqlb-openssl@3"

  # Build scripts require tclsh. `--disable-tcl` only skips building extension
  uses_from_macos "tcl-tk" => :build
  uses_from_macos "sqlite"
  uses_from_macos "zlib"

  def install
    # Determine the minimum macOS version.
    # Match the required version of the DB Browser for SQLite app.
    ENV["MACOSX_DEPLOYMENT_TARGET"] = "10.13"
    ENV.append "CPPFLAGS", "-mmacosx-version-min=10.13"
    ENV.append "LDFLAGS", "-mmacosx-version-min=10.13"

    ENV.append "CFLAGS", "-arch x86_64"

    args = %W[
      --prefix=#{prefix}/darwin64-x86_64-cc
      --enable-tempstore=yes
      --with-crypto-lib=#{Formula["sqlb-openssl@3"].opt_prefix}
      --enable-load-extension
      --disable-tcl
    ]

    # Build with full-text search enabled
    cflags = %w[
      -DSQLCIPHER_CRYPTO_OPENSSL
      -DSQLITE_ENABLE_COLUMN_METADATA
      -DSQLITE_ENABLE_FTS3
      -DSQLITE_ENABLE_FTS3_PARENTHESIS
      -DSQLITE_ENABLE_FTS5
      -DSQLITE_ENABLE_GEOPOLY
      -DSQLITE_ENABLE_JSON1
      -DSQLITE_ENABLE_MEMORY_MANAGEMENT=1
      -DSQLITE_ENABLE_RTREE
      -DSQLITE_ENABLE_SNAPSHOT=1
      -DSQLITE_ENABLE_STAT4
      -DSQLITE_HAS_CODEC
      -DSQLITE_SOUNDEX
    ].join(" ")
    args << "CFLAGS=#{cflags}"

    system "./configure", *args
    system "arch", "-x86_64", "make"
    system "make", "install"

    ENV.delete("CFLAGS")

    args = %W[
      --prefix=#{prefix}
      --enable-tempstore=yes
      --with-crypto-lib=#{Formula["sqlb-openssl@3"].opt_prefix}
      --enable-load-extension
      --disable-tcl
    ]

    # Build with full-text search enabled
    cflags = %w[
      -DSQLCIPHER_CRYPTO_OPENSSL
      -DSQLITE_ENABLE_COLUMN_METADATA
      -DSQLITE_ENABLE_FTS3
      -DSQLITE_ENABLE_FTS3_PARENTHESIS
      -DSQLITE_ENABLE_FTS5
      -DSQLITE_ENABLE_GEOPOLY
      -DSQLITE_ENABLE_JSON1
      -DSQLITE_ENABLE_MEMORY_MANAGEMENT=1
      -DSQLITE_ENABLE_RTREE
      -DSQLITE_ENABLE_SNAPSHOT=1
      -DSQLITE_ENABLE_STAT4
      -DSQLITE_HAS_CODEC
      -DSQLITE_SOUNDEX
    ].join(" ")
    args << "CFLAGS=#{cflags}"

    system "make", "clean"
    system "./configure", *args
    system "make"
    system "make", "install"

    mv "#{lib}/libsqlcipher.0.dylib", "#{lib}/libsqlcipher.0-arm64.dylib"
    dylib_arm64 = MachO::MachOFile.new("#{lib}/libsqlcipher.0-arm64.dylib")
    dylib_x86_64 = MachO::MachOFile.new("#{prefix}/darwin64-x86_64-cc/lib/libsqlcipher.0.dylib")
    fat = MachO::FatFile.new_from_machos(dylib_arm64, dylib_x86_64)
    fat.write("#{lib}/libsqlcipher.0.dylib")

    rm "#{lib}/libsqlcipher.dylib"
    rm_r "#{prefix}/darwin64-x86_64-cc"
    ln_s "#{lib}/libsqlcipher.0.dylib", "#{lib}/libsqlcipher.dylib"
  end

  test do
    path = testpath/"school.sql"
    path.write <<~EOS
      create table students (name text, age integer);
      insert into students (name, age) values ('Bob', 14);
      insert into students (name, age) values ('Sue', 12);
      insert into students (name, age) values ('Tim', json_extract('{"age": 13}', '$.age'));
      select name from students order by age asc;
    EOS

    names = shell_output("#{bin}/sqlcipher < #{path}").strip.split("\n")
    assert_equal %w[Sue Tim Bob], names
  end
end

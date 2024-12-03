class SqlbSqlcipher < Formula
  desc "SQLite extension providing 256-bit AES encryption"
  homepage "https://www.zetetic.net/sqlcipher/"
  version "4.6.1"
  url "https://github.com/sqlcipher/sqlcipher/archive/refs/tags/v#{version}.tar.gz"
  sha256 "d8f9afcbc2f4b55e316ca4ada4425daf3d0b4aab25f45e11a802ae422b9f53a3"
  license "BSD-3-Clause"
  head "https://github.com/sqlcipher/sqlcipher.git", branch: "master"

  bottle do
    root_url "https://nightlies.sqlitebrowser.org/homebrew_bottles"
    rebuild 1
    sha256 arm64_sonoma: "ff81df0c7205ada240dfa3ea9fc29e11882b11ed1625b00b4b6cf3853d555084"
  end

  livecheck do
    url :stable
    strategy :github_latest
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
    system "arch -x86_64 make"
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

    system "make clean"
    system "./configure", *args
    system "make"
    system "make", "install"

    system "lipo", "-create", "-output", "#{lib}/libsqlcipher.0.dylib", "#{lib}/libsqlcipher.0.dylib", "#{prefix}/darwin64-x86_64-cc/lib/libsqlcipher.0.dylib"
    system "lipo", "-create", "-output", "#{lib}/libsqlcipher.a", "#{lib}/libsqlcipher.a", "#{prefix}/darwin64-x86_64-cc/lib/libsqlcipher.a"
    rm "#{lib}/libsqlcipher.dylib"
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

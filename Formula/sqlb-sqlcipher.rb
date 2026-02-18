class SqlbSqlcipher < Formula
  desc "SQLite extension providing 256-bit AES encryption"
  homepage "https://www.zetetic.net/sqlcipher/"
  url "https://github.com/sqlcipher/sqlcipher/archive/refs/tags/v4.13.0.tar.gz"
  # version "4.13.0"
  sha256 "7ca5c11f70e460d6537844185621d5b3d683a001e6bad223d15bdf8eff322efa"
  license "BSD-3-Clause"
  head "https://github.com/sqlcipher/sqlcipher.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/sqlitebrowser/homebrew-tap/releases/download/sqlb-sqlcipher-4.6.1"
    sha256 cellar: :any, arm64_sonoma: "0f918b4a91bf719ad5b8b205900ca845a21e0b730a01f38b3d2f15a63a15dfdc"
  end

  depends_on arch: :arm64
  depends_on "sqlitebrowser/tap/sqlb-openssl@3"

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
      --disable-tcl
      --dll-basename=libsqlcipher
      --enable-load-extension
      --includedir=#{include}/sqlcipher
      --with-tempstore=yes
      LDFLAGS=-lcrypto
    ]

    # Build with full-text search enabled
    cflags = %w[
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
      -DSQLITE_EXTRA_INIT=sqlcipher_extra_init
      -DSQLITE_EXTRA_SHUTDOWN=sqlcipher_extra_shutdown
    ].join(" ")
    args << "CFLAGS=#{cflags}"

    system "./configure", *args
    system "arch", "-x86_64", "make"
    system "make", "install"

    ENV.delete("CFLAGS")

    args = %W[
      --prefix=#{prefix}
      --disable-tcl
      --dll-basename=libsqlcipher
      --enable-load-extension
      --includedir=#{include}/sqlcipher
      --with-tempstore=yes
      LDFLAGS=-lcrypto
    ]

    # Build with full-text search enabled
    cflags = %w[
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
      -DSQLITE_EXTRA_INIT=sqlcipher_extra_init
      -DSQLITE_EXTRA_SHUTDOWN=sqlcipher_extra_shutdown
    ].join(" ")
    args << "CFLAGS=#{cflags}"

    system "make", "clean"
    system "./configure", *args
    system "make"
    system "make", "install"

    mv "#{lib}/libsqlite3.0.dylib", "#{lib}/libsqlite3.0-arm64.dylib"
    dylib_arm64 = MachO::MachOFile.new("#{lib}/libsqlite3.0-arm64.dylib")
    dylib_x86_64 = MachO::MachOFile.new("#{prefix}/darwin64-x86_64-cc/lib/libsqlite3.0.dylib")
    fat = MachO::FatFile.new_from_machos(dylib_arm64, dylib_x86_64)
    fat.write("#{lib}/libsqlite3.0.dylib")

    # Modify file names to avoid conflicting with sqlite. Similar to
    # * Debian  - https://salsa.debian.org/debian/sqlcipher/-/blob/master/debian/rules
    # * Liguros - https://gitlab.com/liguros/liguros-repo/-/blob/develop/dev-db/sqlcipher/sqlcipher-4.12.0.ebuild
    # * OpenBSD - https://codeberg.org/OpenBSD/ports/src/branch/master/databases/sqlcipher/Makefile
    [
      bin/"sqlite3",
      man1/"sqlite3.1",
      lib/"pkgconfig/sqlite3.pc",
      lib/"libsqlite3.a",
      lib/shared_library("libsqlcipher"),
      *lib.glob(shared_library("libsqlite3", "*")),
    ].each do |path|
      basename = path.basename.sub("sqlite3", "sqlcipher")
      if path.symlink?
        source = path.readlink.sub("sqlite3", "sqlcipher")
        rm(path)
        path.dirname.install_symlink source => basename
      else
        path.dirname.install path => basename
      end
    end
    inreplace lib/"pkgconfig/sqlcipher.pc", "-lsqlite3", "-lsqlcipher"

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

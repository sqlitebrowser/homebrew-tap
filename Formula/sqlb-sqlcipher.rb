class SqlbSqlcipher < Formula
  desc "SQLite extension providing 256-bit AES encryption"
  homepage "https://www.zetetic.net/sqlcipher/"
  url "https://github.com/sqlcipher/sqlcipher/archive/refs/tags/v4.19.0.tar.gz"
  # version "4.19.0"
  sha256 "7075f96cbabe45b4ecfc2e6b1745a625f856f695b0827a5506ce9ed85b906aa0"
  license "BSD-3-Clause"
  revision 2
  head "https://github.com/sqlcipher/sqlcipher.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/sqlitebrowser/homebrew-tap/releases/download/sqlb-sqlcipher-4.19.0_2"
    sha256 cellar: :any, arm64_golden_gate: "c57009ca5a5136adff42be3e116fa6475fddb4c08ed3692c0270863d49446aac"
    sha256 cellar: :any, arm64_sequoia:     "ccc2f390460733a98793d1b4477cb25fb4649487051203a58287daa80b40c31f"
  end

  depends_on "sqlitebrowser/tap/sqlb-icu4c" => :build
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

    icu4c = Formula["sqlitebrowser/tap/sqlb-icu4c"]
    icu_args = %W[
      --with-icu-cflags=-I#{icu4c.opt_include}
      --with-icu-ldflags=-L#{icu4c.opt_lib}\ -licui18n\ -licuuc\ -licudata\ -lc++
    ]

    args = %W[
      --prefix=#{prefix}/darwin64-x86_64-cc
      --disable-tcl
      --dll-basename=libsqlcipher
      --enable-load-extension
      --includedir=#{include}/sqlcipher
      --with-tempstore=yes
      LDFLAGS=-lcrypto
    ] + icu_args

    # Build with full-text search enabled
    cflags = %w[
      -DSQLITE_ENABLE_COLUMN_METADATA
      -DSQLITE_ENABLE_DBSTAT_VTAB
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
    ] + icu_args

    # Build with full-text search enabled
    cflags = %w[
      -DSQLITE_ENABLE_COLUMN_METADATA
      -DSQLITE_ENABLE_DBSTAT_VTAB
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

    pkgshare.mkpath
    cp icu4c.opt_prefix/"LICENSE", pkgshare/"LICENSE-ICU"
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

    # Check that the ICU extension is enabled.
    assert_equal "ДВА", shell_output("#{bin}/sqlcipher :memory: \"select upper('два');\"").strip
  end
end

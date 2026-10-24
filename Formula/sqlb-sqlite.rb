class SqlbSqlite < Formula
  desc "Command-line interface for SQLite"
  homepage "https://sqlite.org/index.html"
  url "https://www.sqlite.org/2026/sqlite-autoconf-3540100.tar.gz"
  version "3.54.1"
  sha256 "926ef8d3eab93fbf6e06011901273eec076b25594a4e1cdadd50c987f4f6d64e"
  license "blessing"
  revision 1

  livecheck do
    url :homepage
    regex(%r{href=.*?releaselog/v?(\d+(?:[._]\d+)+)\.html}i)
    strategy :page_match do |page, regex|
      page.scan(regex).map { |match| match&.first&.tr("_", ".") }
    end
  end

  bottle do
    root_url "https://github.com/sqlitebrowser/homebrew-tap/releases/download/sqlb-sqlite-3.54.1"
    sha256 cellar: :any, arm64_golden_gate: "2012f86fdea69f3b959966581ca8e88e9f61e9ced85e2e9a64d1501c52b38963"
    sha256 cellar: :any, arm64_sequoia:     "6efd1d2542a39745239b5658c5c986b967564a39ba8fe8a2e80a7b40af33d2d6"
    sha256 cellar: :any, arm64_sonoma:      "4b02c62deaf7f6dbad0ca51fa50c870f6af45b0a3ddc300cc0884dfbba04f7b3"
  end

  env :std

  keg_only :shadowed_by_macos

  depends_on "sqlitebrowser/tap/sqlb-icu4c" => :build
  depends_on arch: :arm64

  def install
    # Determine the minimum macOS version.
    # Match the required version of the DB Browser for SQLite app.
    ENV["MACOSX_DEPLOYMENT_TARGET"] = "10.13"
    ENV.append "CPPFLAGS", "-mmacosx-version-min=10.13"
    ENV.append "LDFLAGS", "-mmacosx-version-min=10.13 -arch x86_64 -arch arm64"

    ENV.append "CFLAGS", "-arch x86_64 -arch arm64"

    # Default value of MAX_VARIABLE_NUMBER is 999 which is too low for many
    # applications. Set to 250000 (Same value used in Debian and Ubuntu).
    ENV.append "CPPFLAGS", %w[
      -DSQLITE_ENABLE_API_ARMOR=1
      -DSQLITE_ENABLE_COLUMN_METADATA=1
      -DSQLITE_ENABLE_DBSTAT_VTAB=1
      -DSQLITE_ENABLE_FTS3=1
      -DSQLITE_ENABLE_FTS3_PARENTHESIS=1
      -DSQLITE_ENABLE_FTS5=1
      -DSQLITE_ENABLE_GEOPOLY=1
      -DSQLITE_ENABLE_JSON1=1
      -DSQLITE_ENABLE_MATH_FUNCTIONS=1
      -DSQLITE_ENABLE_MEMORY_MANAGEMENT=1
      -DSQLITE_ENABLE_RTREE=1
      -DSQLITE_ENABLE_SNAPSHOT=1
      -DSQLITE_ENABLE_SOUNDEX=1
      -DSQLITE_ENABLE_STAT4=1
      -DSQLITE_ENABLE_UNLOCK_NOTIFY=1
      -DSQLITE_MAX_ATTACHED=125
      -DSQLITE_MAX_VARIABLE_NUMBER=250000
      -DSQLITE_USE_URI=1
    ].join(" ")

    args = %W[
      --prefix=#{prefix}
      --disable-dependency-tracking
      --disable-readline
      --disable-editline
    ]

    icu4c = Formula["sqlitebrowser/tap/sqlb-icu4c"]
    args << "--with-icu-cflags=-I#{icu4c.opt_include}"
    args << "--with-icu-ldflags=-L#{icu4c.opt_lib} -licui18n -licuuc -licudata -lc++"

    system "./configure", *args
    system "make", "install"

    # Avoid rebuilds of dependants that hardcode this path.
    inreplace lib/"pkgconfig/sqlite3.pc", prefix, opt_prefix

    pkgshare.mkpath
    cp icu4c.opt_prefix/"LICENSE", pkgshare/"LICENSE-ICU"
  end

  test do
    path = testpath/"school.sql"
    path.write <<~EOS
      create table students (name text, age integer);
      insert into students (name, age) values ('Bob', 14);
      insert into students (name, age) values ('Sue', 12);
      insert into students (name, age) values ('Tim', 13);
      select name from students order by age asc;
    EOS

    names = shell_output("#{bin}/sqlite3 < #{path}").strip.split("\n")
    assert_equal %w[Sue Tim Bob], names

    # Check that the ICU extension is enabled.
    assert_equal "ДВА", shell_output("#{bin}/sqlite3 :memory: \"select upper('два');\"").strip
  end
end

class Db4ssqliteftsAT5 < Formula
  desc "Command-line interface for SQLite"
  homepage "https://sqlite.org"
  version "3.43.2"
  url "https://sqlite.org/2023/sqlite-autoconf-3430200.tar.gz"
  sha256 "6d422b6f62c4de2ca80d61860e3a3fb693554d2f75bb1aaca743ccc4d6f609f0"

  bottle do
    root_url "https://nightlies.sqlitebrowser.org/homebrew_bottles"
    rebuild 1
    sha256 cellar: :any, monterey: "2697f17e93d3968a9aed113e4c4f523103d2440c90c323f14e37262b8d254008"
    sha256 cellar: :any, arm64_ventura: "c0aad0f3d5bc800a478b2f30b11cc66f9b0fa88e8ea8d0001b6acd1d593cfef9"
    sha256 cellar: :any, arm64_sonoma: "295df21086bfe34c3f03b69d5710e1d138d884935d9a3bdf2e1c824894a2f57d"
  end
  
  livecheck do
    url :homepage
    regex(%r{href=.*?releaselog/v?(\d+(?:[._]\d+)+)\.html}i)
    strategy :page_match do |page, regex|
      page.scan(regex).map { |match| match&.first&.gsub("_", ".") }
    end
  end

  def install
    ENV.append "CPPFLAGS", "-DSQLITE_ENABLE_COLUMN_METADATA=1"
    # Default value of MAX_VARIABLE_NUMBER is 999 which is too low for many
    # applications. Set to 250000 (Same value used in Debian and Ubuntu).
    ENV.append "CPPFLAGS", "-DSQLITE_MAX_VARIABLE_NUMBER=250000"
    ENV.append "CPPFLAGS", "-DSQLITE_ENABLE_RTREE=1"
    ENV.append "CPPFLAGS", "-DSQLITE_ENABLE_GEOPOLY=1"
    ENV.append "CPPFLAGS", "-DSQLITE_ENABLE_FTS3=1 -DSQLITE_ENABLE_FTS3_PARENTHESIS=1"
    ENV.append "CPPFLAGS", "-DSQLITE_ENABLE_FTS5=1"
    ENV.append "CPPFLAGS", "-DSQLITE_ENABLE_STAT4=1"
    ENV.append "CPPFLAGS", "-DSQLITE_ENABLE_JSON1=1"
    ENV.append "CPPFLAGS", "-DSQLITE_SOUNDEX=1"
    ENV.append "CPPFLAGS", "-DSQLITE_ENABLE_MATH_FUNCTIONS=1"
    ENV.append "CPPFLAGS", "-DSQLITE_MAX_ATTACHED=125"

    # Options that sound like they'll be useful
    ENV.append "CPPFLAGS", "-DSQLITE_ENABLE_MEMORY_MANAGEMENT=1"
    ENV.append "CPPFLAGS", "-DSQLITE_ENABLE_SNAPSHOT=1"

    args = %W[
      --prefix=#{prefix}
      --disable-dependency-tracking
      --enable-dynamic-extensions
      --disable-readline
      --disable-editline
    ]

    system "./configure", *args
    system "make", "install"
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
  end
end

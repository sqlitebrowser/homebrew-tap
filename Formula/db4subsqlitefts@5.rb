class Db4subsqliteftsAT5 < Formula
  desc "Command-line interface for SQLite"
  homepage "https://sqlite.org"
  version "3.44.2"
  url "https://sqlite.org/2023/sqlite-autoconf-3440200.tar.gz"
  sha256 "1c6719a148bc41cf0f2bbbe3926d7ce3f5ca09d878f1246fcc20767b175bb407"
  env :std

  bottle do
    root_url "https://nightlies.sqlitebrowser.org/homebrew_bottles"
    rebuild 2
    sha256 cellar: :any, arm64_ventura: "423acff7e1991c175f48f30c9d226badf83e0fe888f4bbb4051906d13464adf8"
    sha256 cellar: :any, arm64_sonoma: "ed81820494ddbedc5f3ce883d1a4822abbfece1bb8e2ca9b4b19ad6c135dae19"
  end
  
  livecheck do
    url :homepage
    regex(%r{href=.*?releaselog/v?(\d+(?:[._]\d+)+)\.html}i)
    strategy :page_match do |page, regex|
      page.scan(regex).map { |match| match&.first&.gsub("_", ".") }
    end
  end

  depends_on arch: :arm64

  def install
    ENV.append "CFLAGS", "-arch x86_64 -arch arm64" if OS.mac? && Hardware::CPU.arm?

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
    system "make"
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

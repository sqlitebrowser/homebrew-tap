class Db4ssqlcipher < Formula
  desc "SQLite extension providing 256-bit AES encryption"
  homepage "https://www.zetetic.net/sqlcipher/"
  url "https://github.com/sqlcipher/sqlcipher/archive/v4.5.5.tar.gz"
  version "4.5.5"
  sha256 "014ef9d4f5b5f4e7af4d93ad399667947bb55e31860e671f0def1b8ae6f05de0"
  head "https://github.com/sqlcipher/sqlcipher.git"

  bottle do
    root_url "https://nightlies.sqlitebrowser.org/homebrew_bottles"
    rebuild 1
    sha256 cellar: :any, monterey: "1875538a4906e595bfd73dfcf8f390288a56ef0149346455034a73bd57d289b2"
    sha256 cellar: :any, arm64_ventura: "3c04a55ee91a62d562f1c51ab35bdd71cc9e10ef991e59981c51bc2ca495bbd9"
  end
  
  depends_on "openssl"

  def install
    args = %W[
      --prefix=#{prefix}
      --enable-tempstore=yes
      --with-crypto-lib=#{Formula["openssl"].opt_prefix}
      --enable-load-extension
      --disable-tcl
    ]

    # Build with full-text search enabled
    args << "CFLAGS=-DSQLITE_HAS_CODEC -DSQLITE_ENABLE_STAT4 -DSQLITE_ENABLE_JSON1 -DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_FTS3_PARENTHESIS -DSQLITE_ENABLE_FTS5 -DSQLITE_ENABLE_GEOPOLY -DSQLITE_ENABLE_RTREE -DSQLITE_SOUNDEX -DSQLITE_ENABLE_MEMORY_MANAGEMENT=1 -DSQLITE_ENABLE_SNAPSHOT=1"

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
      insert into students (name, age) values ('Tim', json_extract('{"age": 13}', '$.age'));
      select name from students order by age asc;
    EOS

    names = shell_output("#{bin}/sqlcipher < #{path}").strip.split("\n")
    assert_equal %w[Sue Tim Bob], names
  end
end

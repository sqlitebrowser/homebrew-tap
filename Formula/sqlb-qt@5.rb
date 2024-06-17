# Patches for Qt must be at the very least submitted to Qt's Gerrit codereview
# rather than their bug-report Jira. The latter is rarely reviewed by Qt.
class SqlbQtAT5 < Formula
  desc "Cross-platform application and UI framework"
  homepage "https://www.qt.io/"
  version "5.15.13"
  # NOTE: Use *.diff for GitLab/KDE patches to avoid their checksums changing.
  url "https://download.qt.io/official_releases/qt/5.15/5.15.13/single/qt-everywhere-opensource-src-5.15.13.tar.xz"
  mirror "https://mirrors.dotsrc.org/qtproject/archive/qt/5.15/5.15.13/single/qt-everywhere-opensource-src-5.15.13.tar.xz"
  mirror "https://mirrors.ocf.berkeley.edu/qt/archive/qt/5.15/5.15.13/single/qt-everywhere-opensource-src-5.15.13.tar.xz"
  sha256 "9550ec8fc758d3d8d9090e261329700ddcd712e2dda97e5fcfeabfac22bea2ca"
  license all_of: ["GFDL-1.3-only", "GPL-2.0-only", "GPL-3.0-only", "LGPL-2.1-only", "LGPL-3.0-only"]
  revision 1

  bottle do
    root_url "https://nightlies.sqlitebrowser.org/homebrew_bottles"
    rebuild 1
    sha256 cellar: :any, arm64_sonoma: "cb257e0ac68b40fde326b7ac0163a64a6e4a46fac96f6c5286a8cb5c8a2daa7f"
  end

  livecheck do
    url "https://download.qt.io/official_releases/qt/5.15/"
    regex(%r{href=["']?v?(\d+(?:\.\d+)+)/?["' >]}i)
  end

  depends_on arch: :arm64
  keg_only :versioned_formula

  # Fix build with Xcode 14.3.
  # https://bugreports.qt.io/browse/QTBUG-112906
  patch do
    url "https://invent.kde.org/qt/qt/qtlocation-mapboxgl/-/commit/5a07e1967dcc925d9def47accadae991436b9686.diff"
    sha256 "4f433bb009087d3fe51e3eec3eee6e33a51fde5c37712935b9ab96a7d7571e7d"
    directory "qtlocation/src/3rdparty/mapbox-gl-native"
  end

  # Fix qmake with Xcode 15.
  # https://bugreports.qt.io/browse/QTBUG-117225
  # Likely can remove with 5.15.16.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/formula-patches/086e8cf/qt5/qt5-qmake-xcode15.patch"
    sha256 "802f29c2ccb846afa219f14876d9a1d67477ff90200befc2d0c5759c5081c613"
  end

  # Fix qtmultimedia build with Xcode 15
  # https://bugreports.qt.io/browse/QTBUG-113782
  # https://github.com/hmaarrfk/qt-main-feedstock/blob/0758b98854a3a3b9c99cded856176e96c9b8c0c5/recipe/patches/0014-remove-usage-of-unary-operator.patch
  patch do
    url "https://raw.githubusercontent.com/Homebrew/formula-patches/3f509180/qt5/qt5-qtmultimedia-xcode15.patch"
    sha256 "887d6cb4fd115ce82323d17e69fafa606c51cef98c820b82309ab38288f21e08"
  end

  # Fix use of macOS 14 only memory_resource on macOS 13
  # The `_cpp_lib_memory_resource` feature test macro should be sufficient but a bug in the SDK means
  # the extra checks are required. This part of the patch will likely be fixed in a future SDK.
  # https://bugreports.qt.io/browse/QTBUG-114316
  # This can likely be removed in 5.15.16.
  patch :p0 do
    url "https://raw.githubusercontent.com/macports/macports-ports/56a9af76a6bcecc3d12c3a65f2465c25e05f2559/aqua/qt5/files/patch-qtbase-memory_resource.diff"
    sha256 "87967d685b08f06e91972a6d8c5e2e1ff672be9a2ba1d7d7084eba1413f641d5"
    directory "qtbase"
  end

  # CVE-2023-32573
  # Original (malformed with CRLF): https://download.qt.io/official_releases/qt/5.15/CVE-2023-32573-qtsvg-5.15.diff
  # Remove with Qt 5.15.14
  patch do
    url "https://invent.kde.org/qt/qt/qtsvg/-/commit/5b1b4a99d6bc98c42a11b7a3f6c9f0b0f9e56f34.diff"
    sha256 "0a978cac9954a557dde7f0c01e059a227f2e064fe6542defd78f37a9f7dd7a3d"
    directory "qtsvg"
  end

  # CVE-2023-32762
  # Original (malformed with CRLF): https://download.qt.io/official_releases/qt/5.15/CVE-2023-32762-qtbase-5.15.diff
  # Remove with Qt 5.15.14
  patch do
    url "https://invent.kde.org/qt/qt/qtbase/-/commit/1286cab2c0e8ae93749a71dcfd61936533a2ec50.diff"
    sha256 "2fba1152067c60756162b7ad7a2570d55c9293dd4a53395197fd31ab770977d7"
    directory "qtbase"
  end

  # CVE-2023-32763
  # Original (malformed with CRLF): https://download.qt.io/official_releases/qt/5.15/CVE-2023-32763-qtbase-5.15.diff
  # Remove with Qt 5.15.15
  patch do
    url "https://invent.kde.org/qt/qt/qtbase/-/commit/deb7b7b52b6e6912ff8c78bc0217cda9e36c4bba.diff"
    sha256 "ceafd01b3e2602140bfe8b052a5ad80ec2f3b3b21aed1e2d6f27cd50b9fb60b7"
    directory "qtbase"
  end

  # CVE-2023-33285
  # Original (malformed with CRLF): https://download.qt.io/official_releases/qt/5.15/CVE-2023-33285-qtbase-5.15.diff
  # Remove with Qt 5.15.14
  patch do
    url "https://invent.kde.org/qt/qt/qtbase/-/commit/21f6b720c26705ec53d61621913a0385f1aa805a.diff"
    sha256 "d2cb352a506a30fa4f4bdf41f887139d8412dfe3dc87e8b29511bd0c990839c5"
    directory "qtbase"
  end

  # CVE-2023-34410
  # Original (malformed with CRLF): https://download.qt.io/official_releases/qt/5.15/CVE-2023-34410-qtbase-5.15.diff
  # KDE patch excludes Windows-specific fixes
  # Remove with Qt 5.15.15
  patch do
    url "https://invent.kde.org/qt/qt/qtbase/-/commit/2ad1884fee697e0cb2377f3844fc298207e810cc.diff"
    sha256 "70496a602600a7133f5f10d8a7554efd7bcbe4d1998b16486da8fb82070b0138"
    directory "qtbase"
  end

  # CVE-2023-37369
  # Remove with Qt 5.15.15
  patch do
    url "https://download.qt.io/official_releases/qt/5.15/CVE-2023-37369-qtbase-5.15.diff"
    sha256 "279c520ec96994d2b684ddd47a4672a6fdfc7ac49a9e0bdb719db1e058d9e5c0"
    directory "qtbase"
  end

  # CVE-2023-38197
  # Remove with Qt 5.15.15
  patch do
    url "https://download.qt.io/official_releases/qt/5.15/CVE-2023-38197-qtbase-5.15.diff"
    sha256 "382c10ec8f42e2a34ac645dc4f57cd6b717abe6a3807b7d5d9312938f91ce3dc"
    directory "qtbase"
  end

  # CVE-2023-51714
  # Remove with Qt 5.15.17
  patch do
    url "https://download.qt.io/official_releases/qt/5.15/0001-CVE-2023-51714-qtbase-5.15.diff"
    sha256 "2129058a5e24d98ee80a776c49a58c2671e06c338dffa7fc0154e82eef96c9d4"
    directory "qtbase"
  end
  patch do
    url "https://download.qt.io/official_releases/qt/5.15/0002-CVE-2023-51714-qtbase-5.15.diff"
    sha256 "99d5d32527e767d6ab081ee090d92e0b11f27702619a4af8966b711db4f23e42"
    directory "qtbase"
  end

  def install
    # Determine the minimum macOS version.
    # Match the required version of the DB Browser for SQLite app.
    ENV["MACOSX_DEPLOYMENT_TARGET"] = "10.13"
    ENV.append "CPPFLAGS", "-mmacosx-version-min=10.13"
    ENV.append "LDFLAGS", "-mmacosx-version-min=10.13"

    args = [
      "-device-option",
      "QMAKE_APPLE_DEVICE_ARCHS=x86_64 arm64",
      "-verbose",
      "-prefix",
      prefix.to_s,
      "-release",
      "-opensource",
      "-confirm-license",
      "-nomake",
      "examples",
      "-nomake",
      "tests",
    ]

    args << "-no-rpath"
    args << "-no-assimp" if Hardware::CPU.arm?

    # Work around Clang failure in bundled Boost and V8:
    # error: integer value -1 is outside the valid range of values [0, 3] for this enumeration type
    if DevelopmentTools.clang_build_version >= 1500
      args << "QMAKE_CXXFLAGS+=-Wno-enum-constexpr-conversion"
      inreplace "qtwebengine/src/3rdparty/chromium/build/config/compiler/BUILD.gn",
                /^\s*"-Wno-thread-safety-attributes",$/,
                "\\0 \"-Wno-enum-constexpr-conversion\","
    end

    system "./configure", *args
    system "make"
    system "make", "install"

    # Install a qtversion.xml to ease integration with QtCreator
    # As far as we can tell, there is no ability to make the Qt buildsystem
    # generate this and it's in the Qt source tarball at all.
    # Multiple people on StackOverflow have asked for this and it's a pain
    # to add Qt to QtCreator (the official IDE) without it.
    # Given Qt upstream seems extremely unlikely to accept this: let's ship our
    # own version.
    # If you read this and you can eliminate it or upstream it: please do!
    # More context in https://github.com/Homebrew/homebrew-core/pull/124923
    qtversion_xml = share/"qtcreator/QtProject/qtcreator/qtversion.xml"
    qtversion_xml.dirname.mkpath
    qtversion_xml.write <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE QtCreatorQtVersions>
      <qtcreator>
      <data>
        <variable>QtVersion.0</variable>
        <valuemap type="QVariantMap">
        <value type="int" key="Id">1</value>
        <value type="QString" key="Name">Qt %{Qt:Version} (#{opt_prefix})</value>
        <value type="QString" key="QMakePath">#{opt_bin}/qmake</value>
        <value type="QString" key="QtVersion.Type">Qt4ProjectManager.QtVersion.Desktop</value>
        <value type="QString" key="autodetectionSource"></value>
        <value type="bool" key="isAutodetected">false</value>
        </valuemap>
      </data>
      <data>
        <variable>Version</variable>
        <value type="int">1</value>
      </data>
      </qtcreator>
    XML

    # Move `*.app` bundles into `libexec` to expose them to `brew linkapps` and
    # because we don't like having them in `bin`.
    bin.glob("*.app") do |app|
      libexec.install app
      bin.write_exec_script libexec/app.basename/"Contents/MacOS"/app.stem
    end
  end

  def caveats
    <<~EOS
      We agreed to the Qt open source license for you.
      If this is unacceptable you should uninstall.

      You can add Homebrew's Qt to QtCreator's "Qt Versions" in:
        Preferences > Qt Versions > Link with Qt...
      pressing "Choose..." and selecting as the Qt installation path:
        #{opt_prefix}
    EOS
  end

  test do
    (testpath/"hello.pro").write <<~EOS
      QT       += core
      QT       -= gui
      TARGET    = hello
      CONFIG   += console
      CONFIG   -= app_bundle
      TEMPLATE  = app
      SOURCES  += main.cpp
    EOS

    (testpath/"main.cpp").write <<~EOS
      #include <QCoreApplication>
      #include <QDebug>

      int main(int argc, char *argv[])
      {
        QCoreApplication a(argc, argv);
        qDebug() << "Hello World!";
        return 0;
      }
    EOS

    # Work around "error: no member named 'signbit' in the global namespace"
    ENV.delete "CPATH"

    system bin/"qmake", testpath/"hello.pro"
    system "make"
    assert_predicate testpath/"hello", :exist?
    assert_predicate testpath/"main.o", :exist?
    system "./hello"
  end
end
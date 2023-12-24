# Patches for Qt must be at the very least submitted to Qt's Gerrit codereview
# rather than their bug-report Jira. The latter is rarely reviewed by Qt.
class Db4subqtAT5 < Formula
  desc "Cross-platform application and UI framework"
  homepage "https://www.qt.io/"
  version "5.15.11"
  # NOTE: Use *.diff for GitLab/KDE patches to avoid their checksums changing.
  url "https://download.qt.io/official_releases/qt/5.15/#{version}/single/qt-everywhere-opensource-src-#{version}.tar.xz"
  mirror "https://mirrors.dotsrc.org/qtproject/archive/qt/5.15/#{version}/single/qt-everywhere-opensource-src-#{version}.tar.xz"
  mirror "https://mirrors.ocf.berkeley.edu/qt/archive/qt/5.15/#{version}/single/qt-everywhere-opensource-src-#{version}.tar.xz"
  sha256 "7426b1eaab52ed169ce53804bdd05dfe364f761468f888a0f15a308dc1dc2951"
  license all_of: ["GFDL-1.3-only", "GPL-2.0-only", "GPL-3.0-only", "LGPL-2.1-only", "LGPL-3.0-only"]

  bottle do
    root_url "https://nightlies.sqlitebrowser.org/homebrew_bottles"
    rebuild 1
    sha256 cellar: :any, arm64_sonoma: "2162426f8c66f7e3aa4e4ea73c106c93d5d2b0014d45091c105645c067501461"
  end
  
  depends_on arch: :arm64

  # Fix build with macOS Sonoma.
  if MacOS.version == :sonoma
    # Patch for QTBUG-117225
    patch do
      url "https://raw.githubusercontent.com/sqlitebrowser/homebrew-tap/main/Patch/QTBUG-117225/QTBUG-117225.diff"
      sha256 "fad8777aa1bfdbb8e74a4b2c9a58c4ca330cad0a273b2dceae87f670332023b2"
      directory "qtbase/"
    end

    # Patch for `unary_function` deprecation.
    patch do
      url "https://raw.githubusercontent.com/sqlitebrowser/homebrew-tap/main/Patch/QT-UNARY_FUNCTION/QT-UNARY_FUNCTION.diff"
      sha256 "d830eb11783b0edcbd547f0bd665e3bce0b3ec067ba4f4e80f5160cfcfb8a77b"
    end
  end

  # Fix build with Xcode 14.3.
  patch do
    url "https://invent.kde.org/qt/qt/qtlocation-mapboxgl/-/commit/5a07e1967dcc925d9def47accadae991436b9686.diff"
    sha256 "4f433bb009087d3fe51e3eec3eee6e33a51fde5c37712935b9ab96a7d7571e7d"
    directory "qtlocation/src/3rdparty/mapbox-gl-native"
  end

  def install
    args = [
      "-device-option", "QMAKE_APPLE_DEVICE_ARCHS=x86_64 arm64", "-verbose", "-prefix", prefix.to_s, "-release", "-opensource", "-confirm-license", "-no-rpath", "-nomake", "examples", "-nomake", "tests"
    ]

    system "./configure", *args

    system "make"
    system "make", "install"
  end

  def caveats
    <<~EOS
      We agreed to the Qt open source license for you.
      If this is unacceptable you should uninstall.
    EOS
  end

  test do
    (testpath/"hello.pro").write <<~EOS
      QT       += core
      QT       -= gui
      TARGET = hello
      CONFIG   += console
      CONFIG   -= app_bundle
      TEMPLATE = app
      SOURCES += main.cpp
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

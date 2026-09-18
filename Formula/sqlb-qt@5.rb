# Patches for Qt must be at the very least submitted to Qt's Gerrit codereview
# rather than their bug-report Jira. The latter is rarely reviewed by Qt.
class SqlbQtAT5 < Formula
  desc "Cross-platform application and UI framework"
  homepage "https://www.qt.io/"
  url "https://download.qt.io/archive/qt/5.15/5.15.19/single/qt-everywhere-opensource-src-5.15.19.tar.xz"
  # version "5.15.19"
  # NOTE: Use *.diff for GitLab/KDE patches to avoid their checksums changing.
  sha256 "173c2326dae138bbb0d98921e9d911e55c00163d93a6db29f294b5e19ff306ae"
  license all_of: ["GFDL-1.3-only", "GPL-2.0-only", "GPL-3.0-only", "LGPL-2.1-only", "LGPL-3.0-only"]

  livecheck do
    skip "Qt 5.15.19 is the final release"
  end

  bottle do
    root_url "https://github.com/sqlitebrowser/homebrew-tap/releases/download/sqlb-qt@5-5.15.19"
    sha256 cellar: :any, arm64_golden_gate: "5330b04ee97dad2f239eb9636eed6fead6f9d10caf9872359bb3def66ebb74b7"
    sha256 cellar: :any, arm64_sequoia:     "266fbd16a36cd3b84ec0b8382062057983525a87559733c71ea4d70af5b9e2ce"
    sha256 cellar: :any, arm64_sonoma:      "0e571ced8d9748c5c8f3a3bbbf52faa66188d01845a9dce4b8696b5b21c8a5b7"
  end

  keg_only :versioned_formula

  depends_on arch: :arm64

  # Fix build with Xcode 14.3.
  patch do
    url "https://invent.kde.org/qt/qt/qtlocation-mapboxgl/-/commit/5a07e1967dcc925d9def47accadae991436b9686.diff"
    sha256 "4f433bb009087d3fe51e3eec3eee6e33a51fde5c37712935b9ab96a7d7571e7d"
    directory "qtlocation/src/3rdparty/mapbox-gl-native"
    type :cherry_pick
    resolves "https://bugreports.qt.io/browse/QTBUG-112906"
  end

  # Fix build with Xcode 26 with backport from Qt6
  # https://github.com/qt/qtbase/commit/cdb33c3d5621ce035ad6950c8e2268fe94b73de5
  patch :DATA

  # Apply patch from Gentoo bug tracker to fix build on macOS.
  # Not possible to upstream as the final Qt5 commercial release is done.
  patch do
    on_sequoia :or_newer do
      url "https://bugs.gentoo.org/attachment.cgi?id=916782"
      sha256 "6b655ba61128c04811e0426a1e25456914fc79c845469da6df10f2d3e29aa510"
      directory "qtlocation"
      type :unofficial
      resolves "https://bugs.gentoo.org/936486"
    end
  end

  # Backport Boost fix for newer Clang
  patch do
    on_tahoe :or_newer do
      url "https://github.com/boostorg/mpl/commit/8499ae7e4ff0cf798367ebe6ea9fb991aa43db6c.patch?full_index=1"
      sha256 "2bac4e4eaabce759c09b86b716149aad8e2bfcc921d7d946a31d24a3b9e25ac3"
      directory "qtlocation/src/3rdparty/mapbox-gl-native/deps/boost/1.65.1"
      type :backport
      resolves "https://github.com/boostorg/mpl/pull/77"
    end
  end
  patch do
    on_tahoe :or_newer do
      url "https://github.com/boostorg/mpl/commit/fb6b861834e29a93ba71a2e2501a42ecfd3c5655.patch?full_index=1"
      sha256 "1213dc3e1b8d9cfc9ed42fc1639f10fa350f2a921d378b184c2c0a1d4936f7f3"
      directory "qtlocation/src/3rdparty/mapbox-gl-native/deps/boost/1.65.1"
      type :backport
      resolves "https://github.com/boostorg/mpl/pull/77"
    end
  end

  # Apply Debian patch to fix build with GCC 13+
  patch do
    url "https://salsa.debian.org/qt-kde-team/qt/qtlocation/-/raw/4ec161bda76cd4c80d2e50fff223a94594cc6b4c/debian/patches/gcc_13.diff"
    sha256 "85ef9bb775540d639cea03894101ab2b7476f633cbb7ff49a1ea0a6bbca82168"
    directory "qtlocation"
    type :unofficial
    resolves "https://github.com/mapbox/mapbox-gl-native/pull/16669"
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
      "-skip",
      "qtwebengine",
    ]

    args << "-no-rpath"
    args << "-no-assimp" if Hardware::CPU.arm?

    # Keep Qt3D x86 SIMD flags out of the arm64 slice of the universal build.
    args += %w[-qt3d-simd no]

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
    assert_path_exists testpath/"hello"
    assert_path_exists testpath/"main.o"
    system "./hello"
  end
end

__END__
--- a/qtbase/mkspecs/common/mac.conf
+++ b/qtbase/mkspecs/common/mac.conf
@@ -18,8 +18,7 @@ QMAKE_LIBDIR            =
 
 # sdk.prf will prefix the proper SDK sysroot
 QMAKE_INCDIR_OPENGL     = \
-    /System/Library/Frameworks/OpenGL.framework/Headers \
-    /System/Library/Frameworks/AGL.framework/Headers/
+    /System/Library/Frameworks/OpenGL.framework/Headers
 
 QMAKE_FIX_RPATH         = install_name_tool -id
 
@@ -30,7 +29,7 @@ QMAKE_LFLAGS_REL_RPATH  =
 QMAKE_REL_RPATH_BASE    = @loader_path
 
 QMAKE_LIBS_DYNLOAD      =
-QMAKE_LIBS_OPENGL       = -framework OpenGL -framework AGL
+QMAKE_LIBS_OPENGL       = -framework OpenGL
 QMAKE_LIBS_THREAD       =
 
 QMAKE_INCDIR_WAYLAND    =
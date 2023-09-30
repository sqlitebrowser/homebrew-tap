cask "db-browser-for-sqlite-3100" do
    version "3.10.0"
    sha256  "b7d5bdc92c4d5b4d1b69203033e75cc537daca00b95e39f737ed32eae728c6aa"

    url "https://github.com/sqlitebrowser/sqlitebrowser/releases/download/v#{version.major_minor_patch}/DB.Browser.for.SQLite-#{version}.dmg"
    name "DB Browser for SQLite"
    desc "Browser for SQLite databases"
    homepage "https://sqlitebrowser.org/"

    livecheck do
        url :url
        strategy :github_latest
    end

    app "DB Browser for SQLite.app"

    zap trash: [
        "~/Library/Preferences/net.sourceforge.sqlitebrowser.plist",
        "~/Library/Saved Application State/net.sourceforge.sqlitebrowser.savedState",
    ]
end
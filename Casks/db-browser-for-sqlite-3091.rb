cask "db-browser-for-sqlite-3091" do
    version "3.9.1"
    sha256  "e4145eae9fb8457431894a3816ae5b90ca8e8122677fae392d18fcbab869afd4"

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
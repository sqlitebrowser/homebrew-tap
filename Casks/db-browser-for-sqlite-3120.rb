cask "db-browser-for-sqlite-3120" do
    version "3.12.0"
    sha256  "4a7aaac7554c43ecec330d0631f356510dcad11e49bb01986ba683b6dfb59530"

    url "https://github.com/sqlitebrowser/sqlitebrowser/releases/download/v#{version}/DB.Browser.for.SQLite-#{version}.dmg"
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
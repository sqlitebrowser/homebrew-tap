cask "db-browser-for-sqlite-3112" do
    version "3.11.2"
    sha256  "022536d420dca87285864a4a948b699d01430721b511722bcf9c8713ab946776"

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
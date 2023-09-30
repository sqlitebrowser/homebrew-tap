cask "db-browser-for-sqlite-3090" do
    version "3.9.0"
    sha256  "6d82db8924c3ff7d9abda45a844fe000db9679255722fb2ebf07b93d9c2f0e11"

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
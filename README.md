# homebrew-tap

## Installation
```
brew tap sqlitebrowser/tap
```

## Casks
| Cask                             | Description                                                  |
| :------------------------------- | :----------------------------------------------------------- |
| db-browser-for-sqlite            | DB Browser for SQLite (Stable)                               |
| db-browser-for-sqlite-nightly    | DB Browser for SQLite (Nightly)                              |
| db-browser-for-sqlcipher-nightly | DB Browser for SQLCipher (Nightly)                           |

<details>
<summary>Older versions</summary>

| Cask                             | Description                              |
| -------------------------------- | ---------------------------------------- |
| db-browser-for-sqlite-3090       | DB Browser for SQLite 3.9.0              |
| db-browser-for-sqlite-3091       | DB Browser for SQLite 3.9.1              |
| db-browser-for-sqlite-3100       | DB Browser for SQLite 3.10.0             |
| db-browser-for-sqlite-3101       | DB Browser for SQLite 3.10.1             |
| db-browser-for-sqlite-3110       | DB Browser for SQLite 3.11.0             |
| db-browser-for-sqlite-3111       | DB Browser for SQLite 3.11.1             |
| db-browser-for-sqlite-3112       | DB Browser for SQLite 3.11.2             |
| db-browser-for-sqlite-3120       | DB Browser for SQLite 3.12.0             |
| db-browser-for-sqlite-3121       | DB Browser for SQLite 3.12.1             |
| db-browser-for-sqlite-3122       | DB Browser for SQLite 3.12.2             |
</details>

## Formulae
| Formula                | Description                          | Need **Rosetta 2** |
| :--------------------- | :----------------------------------- | ------------------ |
| db4sqt@5               | Qt 5.x                               | No                 |
| db4ssqlcipher          | SQLCipher (x86_64)                   | No                 |
| db4ssqlitefts@5        | SQLite 3                             | No                 |
| db4subopenssl@3        | OpenSSL (arm64) for build SQLCipher  | No                 |
| db4subopenssl@3-x86_64 | OpenSSL (x86_64) for build SQLCipher | Yes                |
| db4subqt@5             | Qt 5.x                               | Yes                |
| db4subsqlcipher        | SQLCipher                            | Yes                |
| db4subsqlcipher-x86_64 | SQLCipher (x86_64)                   | Yes                |
| db4subsqlitefts@5      | SQLite 3                             | Yes                |

> [!NOTE]
> You can install Rosetta 2 via `softwareupdate --install-rosetta` command.

> [!WARNING]
> Currently, the official bottle offering for these formulas is only available for macOS Sonoma.  
> If you're using a different version, you need to build from source. Thanks for your understanding.

## License
The code in this repository is licensed under the BSD 2-Clause License.<br>
Please see the [license file](LICENSE) for more information.

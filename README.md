# homebrew-tap
Homebrew tap with the formulae needed to build our [project](https://github.com/sqlitebrowser/sqlitebrowser).

## Installation
```
brew tap sqlitebrowser/tap
```

> [!NOTE]
> Formulae for Intel-based macOS will be available soon.
> Thank you for your patience.

## Formulae
|   **Formula**  | **Description** |
|:--------------:|:---------------:|
| sqlb-openssl@3 |   OpenSSL 3.x   |
|    sqlb-qt@5   |      Qt 5.x     |
| sqlb-sqlcipher |    SQLCipher    |
|   sqlb-sqlite  |      SQLite     |

> [!NOTE]
> This formulae requires Rosetta 2.  
> You can install Rosetta 2 with the command `softwareupdate --install-rosetta`.

> [!WARNING]
> Currently, the official bottle offering for these formulae is only available for macOS Sonoma.  
> If you're using a different version, you'll need to build from source. Thanks for your understanding.

## License
The code in this repository is licensed under the BSD 2-Clause License.<br>
See the [license file](LICENSE) for more information.

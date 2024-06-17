# FileName: check-update.py
# SPDX-FileCopyrightText: (C) 2023 SeongTae Jeong <seongtaejg@gmail.com>
# SPDX-License-Identifier: BSD-2-Clause

"""
This script checks whether the package version of the formulae we're defining
has been updated, and if so, notifies the maintainer by creating a Github Issue.
"""

import os
import re
import requests
import subprocess
from enum import Enum


class IssueVersionStatus(Enum):
    NONE = 0
    EXISTS = 1
    EXISTS_BUT_OUTDATED = 2


class Package(Enum):
    OPENSSL = "OpenSSL"
    QT = "Qt"
    SQLCIPHER = "SQLCipher"
    SQLITE = "SQLite"


def generate_issue(package_name, current_version, latest_version):
    def check_if_issue_exists():
        issue = subprocess.check_output(
            'gh issue list --label "{}" --limit 1 --state "open" --repo "{}"'.format(
                package_name.value, os.environ["GITHUB_REPOSITORY"]
            ),
            shell=True,
            text=True,
        )

        if len(issue) == 0:
            return (IssueVersionStatus.NONE, None)

        issue_number = issue.split("\t")[0]
        version_from_issue = "".join(issue.split("\t")[2].split()[-1:])
        if latest_version == version_from_issue:
            return (IssueVersionStatus.EXISTS, issue_number)
        else:
            return (IssueVersionStatus.EXISTS_BUT_OUTDATED, issue_number)

    issue_info = check_if_issue_exists()
    # Abort function execution because there is already an issue
    if issue_info[0] == IssueVersionStatus.EXISTS:
        return
    # If already have an issue, but the version reported in that issue is already out of date
    elif issue_info[0] == IssueVersionStatus.EXISTS_BUT_OUTDATED:
        os.system(
            'gh issue close {} --repo "{}"'.format(
                issue_info[1], os.environ["GITHUB_REPOSITORY"]
            )
        )
    os.system(
        """
                gh issue create \
                --assignee "{}" \
                --body "{} has been updated from {} to {}." \
                --label "{}" \
                --title "{} has been updated to {}" \
                --repo "{}"
                """.format(
            os.environ["ASSIGNEES"],
            package_name.value,
            current_version,
            latest_version,
            package_name.value,
            package_name.value,
            latest_version,
            os.environ["GITHUB_REPOSITORY"],
        )
    )


def get_version_from_formula(formula_name):
    filepath = os.path.join(os.getcwd(), "Formula", formula_name + ".rb")
    with open(filepath, "r") as formula:
        formula_content = formula.read()
        version = re.search(r'version "(.*?)"', formula_content).group(1)

    return version


def check_sqlcipher_version():
    current_version = get_version_from_formula("sqlb-sqlcipher")

    release_list = subprocess.check_output(
        "gh release list --repo sqlcipher/sqlcipher --limit 1", shell=True, text=True
    )
    latest_version = release_list.split()[0][1:]

    if current_version != latest_version:
        return (Package.SQLCIPHER, current_version, latest_version)


def check_sqlite_version():
    current_version = get_version_from_formula("sqlb-sqlite")

    response = requests.get("https://sqlite.org/index.html")
    latest_version = (
        re.search(r"href=.*?releaselog/v?(\d+(?:[._]\d+)+)\.html", response.text)
        .group(1)
        .replace("_", ".")
    )

    if current_version != latest_version:
        return (Package.SQLITE, current_version, latest_version)


def check_openssl_version():
    current_version = get_version_from_formula("sqlb-openssl@3")

    response = requests.get("https://www.openssl.org/source/")
    latest_version = re.findall(
        r"href=.*?openssl[._-]v?(\d+(?:\.\d+)+)\.t", response.text
    )[-1]

    if current_version != latest_version:
        return (Package.OPENSSL, current_version, latest_version)


def check_qt_version():
    current_version = get_version_from_formula("sqlb-qt@5")

    response = requests.get(
        "https://raw.githubusercontent.com/Homebrew/homebrew-core/master/Formula/q/qt%405.rb"
    )
    latest_version = re.search(r'url "(.*?)"', response.text).group(1).split("/")[-3]

    if current_version != latest_version:
        return (Package.QT, current_version, latest_version)


if __name__ == "__main__":
    functions = [
        check_sqlite_version,
        check_sqlcipher_version,
        check_openssl_version,
        check_qt_version,
    ]
    for function in functions:
        response = function()
        if response is not None:
            generate_issue(response[0], response[1], response[2])

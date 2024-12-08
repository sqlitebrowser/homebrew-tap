# FileName: check-update.py
# SPDX-FileCopyrightText: (C) 2024 SeongTae Jeong <seongtaejg@sqlitebrowser.org>
# SPDX-License-Identifier: BSD-2-Clause

"""
This script checks whether the package version of the formulae we're defining
has been updated, and if so, notifies the maintainer by creating a GitHub issue.
"""

import json
import os
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


def return_package_name_from_formula(formula):
    if formula == "sqlb-openssl@3":
        return Package.OPENSSL
    elif formula == "sqlb-qt@5":
        return Package.QT
    elif formula == "sqlb-sqlcipher":
        return Package.SQLCIPHER
    elif formula == "sqlb-sqlite":
        return Package.SQLITE


if __name__ == "__main__":
    data = json.loads(
        subprocess.run(
            "brew livecheck sqlb-openssl sqlb-qt sqlb-sqlcipher sqlb-sqlite --json",
            shell=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
    )
    for formula in data:
        if formula["version"]["current"] != formula["version"]["latest"]:
            generate_issue(
                return_package_name_from_formula(formula["formula"]),
                formula["version"]["current"],
                formula["version"]["latest"],
            )


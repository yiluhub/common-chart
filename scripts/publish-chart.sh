#!/usr/bin/env bash
set -euo pipefail

VERSION=$(grep 'version: [0-9]\+\.[0-9]\+\.[0-9]\+' "yilu-common/Chart.yaml" | cut -d':' -f2 | tr -d '[:space:]')

if echo "${VERSION}" | grep -Eq "^v[0-9]+(\.[0-9]+){2}$"; then
    REPOSITORY="https://$TRAVIS_GITHUB_TOKEN@raw.githubusercontent.com/yiluhub/common-chart.git"
    git config user.email yilu-bot@users.noreply.github.com
    git config user.name yilu-bot
    git remote set-url origin "${REPOSITORY}"
    helm package yilu-common --dependency-update
    mv yilu-common-"$VERSION".tgz docs
    helm repo index docs --url https://yiluhub.github.io/common-chart/
    cp yilu-common/README.MD docs/
    git add yilu-common
    git commit -m "version $VERSION has been created"
    git push origin master
    echo "✅ Published charts"
else
    echo "Not a valid semver release tag! Skip charts package"
    exit 0
fi

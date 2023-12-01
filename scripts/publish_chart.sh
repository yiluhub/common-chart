#!/usr/bin/env bash
set -eo pipefail

VERSION=$(grep 'version: [0-9]\+\.[0-9]\+\.[0-9]\+' "yilu-common/Chart.yaml" | cut -d':' -f2 | tr -d '[:space:]')
TRAVIS_GITHUB_TOKEN_USERNAME="Travis-CI"
# from the CI
BRANCH_NAME=$CI_BRANCH
LAST_COMMIT_MESSAGE=$CI_COMMIT_MESSAGE

if echo "${VERSION}" | grep -Eq "^[0-9]+(\.[0-9]+){2}$"; then
  if echo "${LAST_COMMIT_MESSAGE}" | grep -Eq "version [0-9]+(\.[0-9]+){2} has been created"; then
    echo "Release VERSION already created! Skipping release generation"
    exit 0
  else
    REPOSITORY="https://$TRAVIS_GITHUB_TOKEN_USERNAME:$TRAVIS_GITHUB_TOKEN@github.com/yiluhub/common-chart.git"
    git config user.email $TRAVIS_GITHUB_TOKEN_USERNAME@users.noreply.github.com
    git config user.name $TRAVIS_GITHUB_TOKEN_USERNAME
    git remote set-url origin "${REPOSITORY}"
    echo "✅ Set remote origin to $REPOSITORY"
    git checkout "$BRANCH_NAME"
    echo "✅ Checking out to $BRANCH_NAME"
    helm package yilu-common --dependency-update
    mv yilu-common-"$VERSION".tgz docs
    helm repo index docs --url https://yiluhub.github.io/common-chart/
    cp yilu-common/README.md docs/
    git add docs/
    git commit -m "version $VERSION has been created"
    git push origin "$BRANCH_NAME"
    echo "✅ Published charts"
  fi
else
    echo "Not a valid semver release tag! Skip charts package"
    exit 0
fi

#!/bin/bash
set -eo pipefail -o nounset

# In conjunction with set -o nounset, the lines below will throw an exception if the
# variables aren't set in the calling environment prior to the script running
: ${CI_BUILD_NUMBER}      # sourced from "${bamboo.buildNumber}"
: ${CI_BRANCH_NAME}       # sourced from "${bamboo.planRepository.branchName}"

ruby_version="$(cat .ruby-version)"

# run the ci build/tests using que's own CI-aware dev environment (builds the dev image,
# runs the spec suite against a real Postgres via docker-compose.yml, tears down containers
# and the db volume on exit)
CI=true ./auto/test

# update gem version
git reset --hard # to keep gem-release happy - there are some diff-index issues in the shebang script

run_docker="docker run -i --rm -v $(pwd):/opt/opschain -w /opt/opschain -e BUNDLE_PATH=.bundle/path -e BUNDLE_JOBS=20 -e BUNDLE_ARTIFACTORY__LIMEPOINT__ENGINEERING='${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}' -e CI_BUILD_NUMBER -e CI_BRANCH_NAME ruby:${ruby_version}"
${run_docker} sh -ec '/opt/opschain/ci/run_build_and_release.sh'

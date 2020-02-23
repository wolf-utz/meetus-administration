#!/usr/bin/env bash

# Function to write a .env file in Build/docker
# This is read by docker-compose and vars defined here are
# used in .ci/docker/docker-compose.yml
# Function to write a .env file in Build/testing-docker
setUpDockerComposeDotEnv() {
  [ -e .env ] && rm .env
  echo "TEST_FILE=${TEST_FILE}" >>.env
  echo "ROOT_DIR=${ROOT_DIR}" >>.env
  echo "EXTRA_TEST_OPTIONS=${EXTRA_TEST_OPTIONS}" >>.env
  echo "PHP_VERSION=${PHP_VERSION}" >>.env
}

# Function to get the real path on mac os.
realpath() {
  if ! pushd $1 &>/dev/null; then
    pushd ${1##*/} &>/dev/null
    echo $(pwd -P)/${1%/*}
  else
    pwd -P
  fi
  popd >/dev/null
}

# Load help text into $HELP
read -r -d '' HELP <<EOF
Extension test runner. Execute unit test suite and some other details.

Usage: $0 [options] [file]

Options:
    -s <...>
        Specifies which test suite to run
            - build: Builds the project (composer)
            - lint: Lints the php files
            - unit (default): PHP unit tests
            - quality: executes code quality checks (phpstan, phpcs, phpmd)
            - find-debugs: Finds usages of debug calls.

    -p <7.4>
        Specifies the PHP minor version to be used
            - 7.4 (default): use PHP 7.4

    -e "<phpunit options>"
        Only with -s functional|unit
        Additional options to send to phpunit (unit & functional tests).
        Starting with "--" must be added after options starting with "-".
        Example -e "-v --filter canRetrieveValueWithGP" to enable verbose output AND filter tests
        named "canRetrieveValueWithGP"

    -h
        Show this help.

Examples:
    # Run unit tests
    .ci/scripts/ciRunner.sh -s build
EOF

# Test if docker-compose exists, else exit out with error
if ! type "docker-compose" >/dev/null; then
  echo "This script relies on docker and docker-compose. Please install" >&2
  exit 1
fi

# Go to the directory this script is located, so everything else is relative
# to this dir, no matter from where this script is called.
THIS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
cd "$THIS_SCRIPT_DIR" || exit 1

# Go to directory that contains the local docker-compose.yml file
cd ../docker || exit 1

# Option defaults
ROOT_DIR=$(realpath $PWD"/../../")
TEST_SUITE="unit"
PHP_VERSION="7.4"
EXTRA_TEST_OPTIONS=""

# Option parsing
# Reset in case getopts has been used previously in the shell
OPTIND=1
# Array for invalid options
INVALID_OPTIONS=()
# Simple option parsing based on getopts (! not getopt)
while getopts ":s:d:p:e:xy:huv" OPT; do
  case ${OPT} in
  s)
    TEST_SUITE=${OPTARG}
    ;;
  p)
    PHP_VERSION=${OPTARG}
    ;;
  e)
    EXTRA_TEST_OPTIONS=${OPTARG}
    ;;
  h)
    echo "${HELP}"
    exit 0
    ;;
  \?)
    INVALID_OPTIONS+=(${OPTARG})
    ;;
  :)
    INVALID_OPTIONS+=(${OPTARG})
    ;;
  esac
done

# Exit on invalid options
if [ ${#INVALID_OPTIONS[@]} -ne 0 ]; then
  echo "Invalid option(s):" >&2
  for I in "${INVALID_OPTIONS[@]}"; do
    echo "-"${I} >&2
  done
  echo >&2
  echo "${HELP}" >&2
  exit 1
fi

# Set $1 to first mass argument, this is the optional test file or test directory to execute
shift $((OPTIND - 1))
if [ -n "${1}" ]; then
  TEST_FILE="${ROOT_DIR}/${1}"
else
  case ${TEST_SUITE} in
  unit)
    TEST_FILE="${ROOT_DIR}/tests/Unit"
    ;;
  esac
fi

# Suite execution
case ${TEST_SUITE} in
build)
  setUpDockerComposeDotEnv
  docker-compose run build
  SUITE_EXIT_CODE=$?
  docker-compose down
  ;;
lint)
  setUpDockerComposeDotEnv
  docker-compose run lint
  SUITE_EXIT_CODE=$?
  docker-compose down
  ;;
unit)
  setUpDockerComposeDotEnv
  docker-compose run unit
  SUITE_EXIT_CODE=$?
  docker-compose down
  ;;
quality)
  setUpDockerComposeDotEnv
  docker-compose run quality
  SUITE_EXIT_CODE=$?
  docker-compose down
  ;;
*)
  echo "Invalid -s option argument ${TEST_SUITE}" >&2
  echo >&2
  echo "${HELP}" >&2
  exit 1
  ;;
esac

exit $SUITE_EXIT_CODE

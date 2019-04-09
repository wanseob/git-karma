#!/bin/bash

source $(dirname "$0")/utils.sh
check_truffle_project
trap kill_ganache SIGINT SIGTERM SIGTSTP EXIT
run_ganache 8546
test_module
exit 0

#!/usr/bin/env bash

echo "Checking if pre-commit hook is up to date"
diff precommit.sh .git/hooks/pre-commit
if [[ $? != 0 ]]
then
    echo "Pre-commit hook is not up to date, please run ./install_precommit_hook.sh and commit again!"
    exit 1
fi
echo "${GIT_DIR}"
./lint.sh

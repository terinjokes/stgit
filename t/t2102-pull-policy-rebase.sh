#!/bin/sh
#
# Copyright (c) 2007 Yann Dirson
#

test_description='Excercise pull-policy "fetch-rebase".'

. ./test-lib.sh

# don't need this repo, but better not drop it, see t1100
#rm -rf .git

# Need a repo to clone
test_create_repo upstream

test_expect_success \
    'Setup upstream repo, clone it, and add patches to the clone' \
    '
    (cd upstream && stg init) &&
    stg clone upstream clone &&
    (cd clone &&
     git repo-config branch.master.stgit.pull-policy fetch-rebase &&
     git repo-config --list &&
     stg new c1 -m c1 &&
     echo a > file && stg add file && stg refresh
    )
    '

test_expect_success \
    'Add non-rewinding commit upstream and pull it from clone' \
    '
    (cd upstream && stg new u1 -m u1 &&
     echo a > file2 && stg add file2 && stg refresh) &&
    (cd clone && stg pull) &&
    test -e clone/file2
    '

# note: with pre-1.5 Git the clone is not automatically recorded
# as rewinding, and thus heads/origin is not moved, but the stack
# is still correctly rebased
test_expect_success \
    'Rewind/rewrite upstream commit and pull it from clone' \
    '
    (cd upstream && echo b >> file2 && stg refresh) &&
    (cd clone && stg pull) &&
    test `wc -l <clone/file2` = 2
    '

# this one ensures the guard against commits does not unduly trigger
test_expect_success \
    'Rewind/rewrite upstream commit and fetch it from clone before pulling' \
    '
    (cd upstream && echo c >> file2 && stg refresh) &&
    (cd clone && git fetch && stg pull) &&
    test `wc -l <clone/file2` = 3
    '

# this one exercises the guard against commits
# (use a new file to avoid mistaking a conflict for a success)
test_expect_success \
    'New upstream commit and commit a patch in clone' \
    '
    (cd upstream && stg new u2 -m u2 &&
     echo a > file3 && stg add file3 && stg refresh) &&
    (cd clone && stg commit && stg new c2 -m c2 &&
     echo a >> file && stg refresh)
    '
test_expect_failure \
    'Try to  and commit a patch in clone' \
    '(cd clone && stg pull)'

test_done
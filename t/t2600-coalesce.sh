#!/bin/sh

test_description='Run "stg coalesce"'

. ./test-lib.sh

test_expect_success 'Initialize StGit stack' '
    stg init &&
    for i in 0 1 2 3; do
        stg new p$i -m "foo $i" &&
        echo "foo $i" >> foo.txt &&
        git add foo.txt &&
        stg refresh
    done
'

test_expect_success 'Coalesce some patches' '
    [ "$(echo $(stg series --applied --noprefix))" = "p0 p1 p2 p3" ] &&
    [ "$(echo $(stg series --unapplied --noprefix))" = "" ] &&
    stg coalesce --name=q0 --message="wee woo" p1 p2 &&
    [ "$(echo $(stg series --applied --noprefix))" = "p0 q0 p3" ] &&
    [ "$(echo $(stg series --unapplied --noprefix))" = "" ]
'

test_expect_success 'Coalesce at stack top' '
    stg coalesce --name=q1 --message="wee woo wham" q0 p3 &&
    [ "$(echo $(stg series --applied --noprefix))" = "p0 q1" ] &&
    [ "$(echo $(stg series --unapplied --noprefix))" = "" ]
'

cat > editor <<EOF
#!/bin/sh
echo "Editor was invoked" | tee editor-invoked
EOF
chmod a+x editor
test_expect_success 'Coalesce with top != head' '
    echo blahonga >> foo.txt &&
    git commit -a -m "a new commit" &&
    EDITOR=./editor command_error stg coalesce --name=r0 p0 q1 &&
    test "$(echo $(stg series))" = "+ p0 > q1" &&
    test ! -e editor-invoked
'

test_done

#!/bin/bash
#
# This script is run in the "Aggregate documentation" github workflow.
#
# The script receives a repository through the workflow_dispatch trigger, and
# will then clone that repositories main branch, and copy files from that repo
# into this one according to the mappings in aggregate-mappings.json.
#

set -e

echo "Aggregating files"

for repo in $@
do
    # clone repo into a temp dir
    tempdir="$(mktemp -d)"
    git clone "https://github.com/$repo" "$tempdir/${repo#*/}"

    # get file mappings from mappings file
    repo_mappings=$(jq .["\"$repo\""] < aggregate-mappings.json)
    for key in $(jq -r 'keys[]' <<< $repo_mappings)
    do
        target=$(jq -r .["\"$key\""] <<< "$repo_mappings")
        cp $tempdir/${repo#*/}/$key $target
    done

    # check if there are any changes
    if [ ! -z "$(git diff)" ]
    then
        # commit files to repo
        msg=$(date +"Update from $repo at %H:%M on %Y-%m-%d")

        git config --global user.name 'Github aggregate action'
        git config --global user.email 'aggregate@users.noreply.github.com'
        git commit -am "$msg"
        git push
    else
        echo "No changes to commit"
    fi

    # clean up temp dir
    rm -rf "$tempdir"

done

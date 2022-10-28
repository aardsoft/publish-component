#!/bin/bash

public_release=0
public_doc_release=0
name=$(basename `pwd`)
component=ansible

if [ -f .pkg_meta ]; then
    . .pkg_meta
fi

version=`git describe --tags --exact-match`
if [ -z "$version" ]; then
    # dirty
    rsync --delete --delete-excluded --exclude .git -avp -e "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" ${publish_dir}/ de1dochead_pub@www1-de.aardsoft.fi:${component}/${name}/
else
    archive_name=${name}-${version}

    for dir in public private; do
        mkdir -p ${release_dir}/${dir}

        if [ $dir != "public" ] || [ $public_release -eq 1 ]; then
            tar --exclude export-settings.user --exclude style --exclude doc --transform "s,^,$archive_name/," -cjf ${release_dir}/${dir}/${archive_name}.tar.bz2 *
        fi

        if [ $dir != "public" ] || [ $public_release -eq 1 ] || [ $public_doc_release -eq 1 ]; then
            tar --exclude .git --transform "s/^doc/${archive_name}/" -cjf ${release_dir}/${dir}/${archive_name}-doc-raw.tar.bz2 doc
            tar -P --exclude .git --transform "s,^${publish_dir},${archive_name}," -cjf ${release_dir}/${dir}/${archive_name}-doc.tar.bz2 ${publish_dir}
        fi
    done

    # TODO: add syncing for private releases
    rsync -avp -e "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" ${release_dir}/public de1doc_pub@www1-de.aardsoft.fi:archives/
fi

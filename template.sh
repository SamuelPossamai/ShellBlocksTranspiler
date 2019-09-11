#!/bin/bash

function __SHELLFROMBLOCKS_i__BLOCK_FINISH {

    case $1 in
    {% for block in blocks %}{% if 'output' in block %}
        {{ block['name'] }})
            echo {{ ' '.join(create_out_list(blocks, block)) }};;
    {% endif %}{% endfor %}
    esac
}

{% for block in blocks %}
function __SHELLFROMBLOCKS_f__{{ block['name'] }} {
    __SHELLFROMBLOCKS_i__DO_BEFORE
    {% for line in block['config']['Script'].split('\n') %}{% if line %}
    {{ line }}{% endif %}{% endfor %}

    __SHELLFROMBLOCKS_i__DO_AFTER
}

{% endfor %}

export __SHELLFROMBLOCKS_v__LOCK_FILE_BASE="/tmp/__shellfromblocks_lock_$$"
export __SHELLFROMBLOCKS_v__CHILD_ID_FILE="/dev/shm/__shellfromblocks_$$_child_id"

declare -A __SHELLFROMBLOCKS_v__JOB_LIST

function __SHELLFROMBLOCKS_i__LOCK {

    local lock_suffix

    if [ "$1" ] ; then
        lock_suffix=$1
    else
        lock_suffix='global'
    fi

    while true
    do
        lockfile -r 0 ${__SHELLFROMBLOCKS_v__LOCK_FILE_BASE}_$lock_suffix &> /dev/null && break
        sleep 0.002
    done
}

function __SHELLFROMBLOCKS_i__UNLOCK {

    local lock_suffix

    if [ "$1" ] ; then
        lock_suffix=$1
    else
        lock_suffix='global'
    fi

    rm -f ${__SHELLFROMBLOCKS_v__LOCK_FILE_BASE}_$lock_suffix
}

function __SHELLFROMBLOCKS_i__DO_BEFORE {

    true
}

function __SHELLFROMBLOCKS_i__DO_AFTER {

    __SHELLFROMBLOCKS_i__LOCK
    __SHELLFROMBLOCKS_i__LOCK child_id_write
    echo $BASHPID > $__SHELLFROMBLOCKS_v__CHILD_ID_FILE
    __SHELLFROMBLOCKS_i__UNLOCK
}

function __SHELLFROMBLOCKS_i__P_FINISHED {

    for job in $(__SHELLFROMBLOCKS_i__BLOCK_FINISH $1)
    do
        __SHELLFROMBLOCKS_f__$job &
        __SHELLFROMBLOCKS_v__JOB_LIST[$!]=$job
    done
}

__SHELLFROMBLOCKS_i__P_FINISHED main

while true
do
    wait -n

    __SHELLFROMBLOCKS_i__LOCK
    __SHELLFROMBLOCKS_i__P_FINISHED ${__SHELLFROMBLOCKS_v__JOB_LIST[$(cat $__SHELLFROMBLOCKS_v__CHILD_ID_FILE)]}
    rm -f $__SHELLFROMBLOCKS_v__CHILD_ID_FILE
    __SHELLFROMBLOCKS_i__UNLOCK child_id_write
    __SHELLFROMBLOCKS_i__UNLOCK

    if ! jobs %% &> /dev/null; then
        break
    fi
done

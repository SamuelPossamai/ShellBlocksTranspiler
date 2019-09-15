#!/bin/bash

function __SHELLFROMBLOCKS_i__BLOCK_FINISH {

    case $1 in
    {% for block in blocks %}{% if 'output' in block %}
        {{ block['name'] }})
            echo {{ ' '.join(create_out_list(blocks, block)) }};;
    {% endif %}{% endfor %}
    esac
}

{% for block in script_blocks %}
function __SHELLFROMBLOCKS_f__{{ block['name'] }} {
    __SHELLFROMBLOCKS_i__DO_BEFORE
    {% for line in block['config']['Script'].split('\n') %}{% if line %}
    {{ line }}{% endif %}{% endfor %}

    __SHELLFROMBLOCKS_i__DO_AFTER
}

{% endfor %}
{% for block in sync_blocks %}
function __SHELLFROMBLOCKS_f__{{ block['name'] }} {
    __SHELLFROMBLOCKS_i__DO_SYNC "{{ block['name'] }}" $2 "{{ block['inputs'] }}"
}

{% endfor %}
export __SHELLFROMBLOCKS_v__SHMEM_BASENAME="/dev/shm/__shellfromblocks_$$"
export __SHELLFROMBLOCKS_v__SYNC_FILE_BASE="${__SHELLFROMBLOCKS_v__SHMEM_BASENAME}_sync_file"
export __SHELLFROMBLOCKS_v__LOCK_FILE_BASE="/tmp/__shellfromblocks_lock_$$"
export __SHELLFROMBLOCKS_v__CHILD_ID_FILE="${__SHELLFROMBLOCKS_v__SHMEM_BASENAME}_child_id"

declare -A __SHELLFROMBLOCKS_v__JOB_LIST

function __SHELLFROMBLOCKS_i__DO_SYNC {
    __SHELLFROMBLOCKS_i__DO_BEFORE

    local filename_base
    local i

    filename_base="${__SHELLFROMBLOCKS_v__SYNC_FILE_BASE}_$1_"

    echo '1' > "${filename_base}$2"

    for(( i = 0 ; i < $3; i++))
    do
        [ "$(cat ${filename_base}$i 2> /dev/null)" = '1' ] || exit
    done

    for(( i = 0 ; i < $3; i++))
    do
        echo '0' > "${filename_base}$i"
    done

    __SHELLFROMBLOCKS_i__DO_AFTER
}

function __SHELLFROMBLOCKS_i__LOCK {

    local lock_suffix

    if [ "$1" ] ; then
        lock_suffix=$1
    else
        lock_suffix='global'
    fi

    lockfile -0.02 -r -1 ${__SHELLFROMBLOCKS_v__LOCK_FILE_BASE}_$lock_suffix &> /dev/null
}

function __SHELLFROMBLOCKS_i__TRYLOCK {

    local lock_suffix

    if [ "$1" ] ; then
        lock_suffix=$1
    else
        lock_suffix='global'
    fi

    lockfile -r 0 ${__SHELLFROMBLOCKS_v__LOCK_FILE_BASE}_$lock_suffix &> /dev/null

    return $?
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

    while true
    do
        __SHELLFROMBLOCKS_i__LOCK
        if ! __SHELLFROMBLOCKS_i__TRYLOCK child_id_write ; then
            __SHELLFROMBLOCKS_i__UNLOCK
            continue
        fi
        echo $BASHPID > $__SHELLFROMBLOCKS_v__CHILD_ID_FILE
        __SHELLFROMBLOCKS_i__UNLOCK

        sleep 0.02
        break
    done
}

function __SHELLFROMBLOCKS_i__P_FINISHED {

    local job_info
    local job
    local input_number
    local output_number

    for job_info in $(__SHELLFROMBLOCKS_i__BLOCK_FINISH $1)
    do
        job=${job_info%@#*}
        input_number=${job_info##*@#}
        output_number=${input_number%:*}
        input_number=${input_number#*:}
        __SHELLFROMBLOCKS_f__$job $output_number $input_number &
        __SHELLFROMBLOCKS_v__JOB_LIST[$!]=$job
    done
}

{% for block in init_blocks %}
__SHELLFROMBLOCKS_i__P_FINISHED {{ block['name'] }}
{% endfor %}

while true
do
    wait -n

    __SHELLFROMBLOCKS_i__LOCK

    __SHELLFROMBLOCKS_mv__CHILD_ID=$(cat $__SHELLFROMBLOCKS_v__CHILD_ID_FILE 2> /dev/null)

    if [ "$__SHELLFROMBLOCKS_mv__CHILD_ID" ] ; then
        __SHELLFROMBLOCKS_i__P_FINISHED ${__SHELLFROMBLOCKS_v__JOB_LIST[$__SHELLFROMBLOCKS_mv__CHILD_ID]}
        rm -f $__SHELLFROMBLOCKS_v__CHILD_ID_FILE
    fi

    if ! jobs %% &> /dev/null; then
        break
    fi

    __SHELLFROMBLOCKS_i__UNLOCK child_id_write
    __SHELLFROMBLOCKS_i__UNLOCK

done

rm -f $__SHELLFROMBLOCKS_v__SHMEM_BASENAME*

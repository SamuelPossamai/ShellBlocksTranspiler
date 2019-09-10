#!/bin/bash

function __SHELLFROMBLOCKS_i__BLOCK_FINISH {

    local out_list;

    case $1 in
    {% for block in blocks %}{% if 'output' in block %}
        {{ block['name'] }})
            echo {{ ' '.join(create_out_list(blocks, block)) }};;
    {% endif %}{% endfor %}
    esac
}

{% for block in blocks %}
function __SHELLFROMBLOCKS_f__{{ block['name'] }} {
    {% for line in block['config']['Script'].split('\n') %}{% if line %}
    {{ line }}{% endif %}{% endfor %}
}

{% endfor %}

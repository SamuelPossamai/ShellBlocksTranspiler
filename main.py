
import sys
import json

def main():
    if len(sys.argv) != 3:
        print('Wrong number of arguments', file=sys.stderr)

    with open(sys.argv[1]) as in_file:
        file_content = json.load(in_file)

    with open(sys.argv[2], 'w') as out_file:

        out_file.write("""
#!/bin/bash

function __SHELLFROMBLOCKS_i__BLOCK_FINISH {

    local out_list;

    case $1 in""")

        for block in file_content:

            out_list = ( file_content[out_block['block']]['name'] for out_block in block.get('output') or ())

            out_file.write(f"""
        {block['name']})
            out_list="{' '.join(out_list)}";;""")
            block['name']

        out_file.write("""
    esac
}""")

if __name__ == '__main__':
    main()

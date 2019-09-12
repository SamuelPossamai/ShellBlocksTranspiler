
import sys
import json

from jinja2 import Environment, FileSystemLoader

def create_out_list(blocks, block):

    output = block.get('output')

    if output is None:
        return ()

    return (blocks[out_block['block']]['name']
            for out_block in block.get('output'))

def main():

    jinja_env = Environment(loader=FileSystemLoader('.'))

    if len(sys.argv) != 3:
        print('Wrong number of arguments', file=sys.stderr)

    with open(sys.argv[1]) as in_file:
        blocks = json.load(in_file)

    with open(sys.argv[2], 'w') as out_file:

        script_blocks = tuple((block for block in blocks
                               if block['type'] == 'ScriptBlock'))

        init_blocks = tuple((block for block in blocks
                             if block['type'] == 'Init'))

        template = jinja_env.get_template('template.sh')
        write_content = template.render(blocks=blocks,
                                        create_out_list=create_out_list,
                                        script_blocks=script_blocks,
                                        init_blocks=init_blocks)

        out_file.write(write_content)

if __name__ == '__main__':
    main()

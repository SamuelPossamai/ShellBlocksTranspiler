# ShellBlocksTranspiler

This program can be used to translate a program generated using
_BlockConnectorServer_ with a custom _blocktypeconfig.json_ file.

First you need to install _BlockConnectorServer_ program that can be
found [here](https://github.com/SamuelPossamai/BlockConnectorServer.git).
After installing its dependencies(_npm install_), you need to copy
_blocktypeconfig.json_ file in this repository to _BlockConnectorServer_
base directory then run it(_npm start_) and access _localhost:6178_ in 
your preferred browser(javascript must be enabled and may not work in older 
browsers), there you can edit the connections and create the block/shell
program.

The block program will determine the order and syncronization of minor
_bash_ scripts that will not be transpiled and will be copied as they are
t, so the blocks won't write the core of the script for you, but instead 
they have the purpose of helping to organize the sequence of instructions
and their syncronization.

The command _python3 source_file.json dest_file.sh_ will transpile the blocks
and link with your own _bash_ script that you wrote inside the blocks and
translate into a single bash file.

I don't recomend the use o file generated by this software for a real
application. This software is not very developed yet.

The current generated code depend on _lockfile_, a program that is does
not come by default in a lot of *distro*s(including the one that I use), in 
the future I plan to fix it, but for now, the script won't run without 
installing in those *distro*s.

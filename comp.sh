/opt/pccts/bin/antlr -gt plumber.g
/opt/pccts/bin/dlg -ci parser.dlg scan.c
g++ -o plumber plumber.c scan.c err.c -I/home/soft/PCCTS_v1.33/include/ -Wno-write-strings

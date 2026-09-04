import os
import sys

#This script can combine multiple files according to the first column
#Usage:python combineFilesByName.py filenameslist outfile
#ls 1.txt 2.txt > filenameslist


filenames = open(sys.argv[1])

otudata = {}
files = []

for f in filenames:
    files.append(f.strip())

for f in files:
    print(f)
    otutable = open(f)
    for line in otutable:
        line = line.strip().split("\t")
        if line[0] not in otudata:
            otudata[line[0]] = {}
            otudata[line[0]][f] = line[1]
        else:
            otudata[line[0]][f] = line[1]
    otutable.close()


outfile = open(sys.argv[2],'w')


header = "Name"


for f in files:
    header = header + '\t' + f

outfile.write(header+'\n')

for key in otudata:
    out = key
    for f in files:
        if f in otudata[key]:
            out = out + '\t' + otudata[key][f]
        else:
            out = out + '\t' + '0'
    outfile.write(out+'\n')

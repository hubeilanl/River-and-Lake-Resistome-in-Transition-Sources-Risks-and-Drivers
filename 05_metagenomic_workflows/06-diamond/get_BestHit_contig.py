#Usage:
#1. sort -k1,1 -k12,12nr raw.bln > sort.bln
#2. python get_BestHit_contig.py raw.bln best.bln 


import sys
import os

sortedblast = open(sys.argv[1])
output = open(sys.argv[2],'w')
cover = set()
query = ""


for line in sortedblast:
	lineArr = line.strip().split()
	if query != lineArr[0]:
		query = lineArr[0]
		cover = set()
	hitcover = set()
	if int(lineArr[7]) > int(lineArr[6]):
		hitcover = set(range(int(lineArr[6]),int(lineArr[7])+1))
	else:
		hitcover = set(range(int(lineArr[7]),int(lineArr[6])+1))
	
	if len(cover.intersection(hitcover))/float(len(hitcover)) < 0.10:
		cover.update(hitcover)
		output.write(line.strip() + "\n")

	

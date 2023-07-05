#!/apps/ufrc/python/3.8/bin/python
import sys
input=sys.argv[1].split("\n")[-1]
print(input.split(" ")[-1].split(",")[-3])
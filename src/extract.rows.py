"""

 
  Hua Sun
  1/19/2019

  Extract data based on sample list

  python3 run.py --list sample.list --matrix input.tsv --colName SampleID -o output
  
  -l|--list <file>
  -m|--matrix <file>
  -c|--colName <str>
  -o|--outfile <file>

    sample.list (header=F)
    sample1

    input.tsv
    loci sample1 sample2 ... (header=T)

"""

import argparse
import pandas as pd
import re
import os


# collect input arguments
parser = argparse.ArgumentParser()

parser.add_argument('-l', '--list', type=str, required=True, help='sample list')
parser.add_argument('-m', '--matrix', type=str, required=True, help='matrix')
parser.add_argument('-c', '--colName', type=str, required=True, help='column name')
parser.add_argument('-o', '--outfile', type=str, required=True, help='outfile')

args = parser.parse_args()



# read sample list
sampleList = [line.rstrip('\n') for line in open(args.list)]
# read matrix
df = pd.read_csv(args.matrix, sep = "\t", low_memory=False)


df_rows = df.loc[(df[args.colName].isin(sampleList))]

df_rows.to_csv(args.outfile, sep = "\t", index = False, header = True)



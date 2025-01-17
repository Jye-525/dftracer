#!/bin/bash

# This script allows users to combine all pfw format into one.
# This has the following signature.
#
# usage: merge_pfw.sh [-fcv] [-d input_directory] [-o OUTPUT_FILE]
#  -f                      override output file
#  -c                      compress output file
#  -v                      enable verbose mode
#  -h                      display help
#  -d input_directory      specify input directories. should contain .pfw or .pfw.gz files.
#  -o output_file          specify output file. should have extension .pfw

override=0
folder=$PWD
compressed=0
dest="combined.pfw"

function usage {
    echo "usage: $(basename $0) [-fcv] [-d input_directory] [-o OUTPUT_FILE]"
    echo "  -f                      override output file"
    echo "  -c                      compress output file"
    echo "  -v                      enable verbose mode"
    echo "  -h                      display help"
    echo "  -d input_directory      specify input directories. should contain .pfw or .pfw.gz files."
    echo "  -o output_file          specify output file. should have extension .pfw"
    exit 1
}
while getopts ':cvfd:o:h' opt; do
  case "$opt" in
    d)
      folder="${OPTARG}"
      ;;

    o)
      dest="${OPTARG}"
      if [[ $dest != *.pfw ]]; then
        echo "output_file should have .pfw extension".
      fi
      ;;

    f)
      override=1
      ;;
    v)
      set -x
      ;;
    c)
      compressed=1
      ;;
    h)
      usage
      exit 0
      ;;

    :)
      echo -e "option requires an argument.\n"
      usage
      exit 1
      ;;

    ?)
      echo -e "Invalid command option.\n"
      usage
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"

if [[ "$override" == "1" ]]; then
rm -rf $dest ${dest}.gz
fi

pfw_count=`ls -1 $folder/*.pfw 2> /dev/null | wc -l`
gz_count=`ls -1 $folder/*.gz 2> /dev/null | wc -l`
total=$((pfw_count + gz_count))
if [ $total == 0 ]; then
    echo "The folder does not contain any pfw or pfw.gz files."
    exit 0
fi

if [[ "$compressed" == "1" ]]; then
  if [ -f "$dest.gz" ] && [ "$override" -eq "0" ]; then
      echo "The destination file exists. Please delete the file."
      exit 0
  fi
else
  if [ -f $dest ] && [ "$override" -eq "0" ]; then
      echo "The destination file exists. Please delete the file."
      exit 0
  fi
fi

d2=${dest}.bak
shopt -s dotglob
if [[ "$pfw_count" != "0" ]]; then
  echo "Parsing pfw files from ${folder} folder"
  cat `echo $folder/*.pfw` >> $d2
fi

if [[ "$gz_count" != "0" ]]; then
  echo "Parsing pfw.gz files from ${folder} folder"
  gzip -c -d `echo $folder/*.gz` >> $d2
fi

sed -i 's/^\[//g;/^$/d;s/^ *//;s/ *$//' $d2
tmp_file=$(mktemp)
echo "[" | cat - $d2 > $tmp_file && mv $tmp_file $dest
rm -rf $tmp_file

echo "Extracting events"

sed -i 's/^\[//g;/^$/d;s/^ *//;s/ *$//' $d2
tmp_file=$(mktemp)
echo "[" | cat - $d2 > $tmp_file && mv $tmp_file $dest
rm -rf $tmp_file

if [ "$compressed" == "1" ]; then
  echo "Compressing events"
  gzip $dest
  echo "Created output file ${dest}.gz"
else
  echo "Created output file ${dest}"
fi
rm $d2

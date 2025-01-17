#!/bin/bash

# The script compacts all trace file and then divides the trace into equal file pieces.
# This has the following signature.
#
# usage: dftracer_compact [-fcv] [-d input_directory] [-o output_directory] [-l num_lines] [-p prefix]
#   -f                      override output directory
#   -c                      compress output file
#   -v                      enable verbose mode
#   -h                      display help
#   -d input_directory      specify input directories. should contain .pfw or .pfw.gz files.
#   -o output_directory     specify output directory.
#   -l num_lines            lines per trace.
#   -p prefix               prefix to be used for compact files.

LOG_DIR=$PWD
OUTPUT_DIR=$PWD/output
LINES=10000
PREFIX=app
override=0
compressed=0

PPWD=$PWD

function usage {
    echo "usage: $(basename $0) [-fcv] [-d input_directory] [-o output_directory] [-l num_lines] [-p prefix]"
    echo "  -f                      override output directory"
    echo "  -c                      compress output file"
    echo "  -v                      enable verbose mode"
    echo "  -h                      display help"
    echo "  -d input_directory      specify input directories. should contain .pfw or .pfw.gz files."
    echo "  -o output_directory     specify output directory."
    echo "  -l num_lines            lines per trace."
    echo "  -p prefix               prefix to be used for compact files."
    exit 1
}
while getopts ':cvfd:o:l:p:h' opt; do
  case "$opt" in
    d)
      LOG_DIR="${OPTARG}"
      ;;
    o)
      OUTPUT_DIR="${OPTARG}"
      ;;
    l)
      LINES=${OPTARG}
      ;;
    p)
      PREFIX="${OPTARG}"
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

mkdir -p ${OUTPUT_DIR}

if [ -z "$( ls -A '${OUTPUT_DIR}' )" ] && [ $override -eq 0 ]; then
  echo "The directory is not empty. Please pass a clean directory or pass -f flag."
  exit 0
fi

echo "Setting up output directory"
rm -rf ${OUTPUT_DIR}
mkdir -p ${OUTPUT_DIR}

pfw_count=`ls -1 $LOG_DIR/*.pfw 2> /dev/null | wc -l`
gz_count=`ls -1 $LOG_DIR/*.gz 2> /dev/null | wc -l`
total=$((pfw_count + gz_count))
if [ $total == 0 ]; then
    echo "The folder does not contain any pfw or pfw.gz files."
    exit 0
fi
dest=${OUTPUT_DIR}/temp
d2=${dest}.bak
shopt -s dotglob
if [[ "$pfw_count" != "0" ]]; then
echo "Parsing pfw files from ${LOG_DIR} folder"
ls ${LOG_DIR}/*.pfw | xargs cat | grep -v "^\[" | jq -c '.' > $d2
fi

if [[ "$gz_count" != "0" ]]; then
echo "Parsing pfw.gz files from ${LOG_DIR} folder"
gzip -c -d `echo $folder/*.gz` | grep -v "^\[" | jq -c '.' >> $d2
fi

cd ${OUTPUT_DIR}

echo "Compacting all trace files with ${LINES} per files into ${OUTPUT_DIR} folder."
split -l ${LINES} --numeric-suffixes  --additional-suffix=.pfw $d2 ${PREFIX}-
for file in *.pfw; do
    echo "[" > $file.$$
    cat $file >> $file.$$
    mv $file.$$ $file
done
rm $d2
if [ $compressed == 1 ]; then
gzip ${PREFIX}-*.pfw
fi

cd $PPWD

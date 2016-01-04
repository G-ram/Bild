#!/bin/sh

PROG="./bild"

# Some colors
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Set time limit for all operations
ulimit -t 30

globallog=tests.log
rm -f $globallog
error=0
globalerror=0

keep=0

successes=0
failures=0
totalTests=0

Usage() {
    echo "Usage: test.sh [options] [.bd files]"
    echo "-k    Keep intermediate files"
    echo "-h    Print this help"
    exit 1
}

SignalError() {
    if [ $error -eq 0 ] ; then
    printf "${RED}FAILED${NC}"
    error=1
    fi
    echo "  $1"
}

# Compare <outfile> <reffile> <difffile>
# Compares the outfile with reffile.  Differences, if any, written to difffile
Compare() {
    generatedfiles="$generatedfiles $3"
    echo diff -b $1 $2 ">" $3 1>&2
    diff -b "$1" "$2" > "$3" 2>&1 || {
    SignalError "$1 differs"
    echo "FAILED $1 differs from $2" 1>&2
    }
}

# Run <args>
# Report the command, run it, and report any errors
Run() {
    echo $* 1>&2
    eval $* || {
    errorcommand=$(echo "$*" | cut -c 1-50)
    SignalError "$1 failed on $errorcommand..."
    return 1
    }
}

Check() {
    error=0
    basename=`echo $1 | sed 's/.*\\///
                             s/.bd//'`
    echo "###### Testing ${CYAN} $basename ${NC} ######"
    basename="tests/failures/$basename"
    reffile=`echo $1 | sed 's/.bd$//'`
    basedir="`echo $1 | sed 's/\/[^\/]*$//'`/."

    echo 1>&2
    echo "###### Testing $basename" 1>&2

    generatedfiles=""
    startms=$(ruby -e 'puts (Time.now.to_f * 1000).to_i')

    generatedfiles="$generatedfiles ${basename}.out" &&
    Run "$PROG" $1 ">" "Program.java && javac Program.java && java Program >" ${basename}.out &&
    Compare ${basename}.i.out ${reffile}.out ${basename}.i.diff

    endms=$(ruby -e 'puts (Time.now.to_f * 1000).to_i')
    elapsedms=$((endms - startms))
    echo "Done in ${CYAN} $elapsedms ${NC} ms"
    # Report the status and clean up the generated files

    if [ $error -eq 0 ] ; then
    if [ $keep -eq 0 ] ; then
        rm -f $generatedfiles
    fi
    echo "${CYAN}SUCCESS${NC}"
    echo "###### SUCCESS" 1>&2
    ((successes++))
    ((totalTests++))
    else
    echo "###### FAILED" 1>&2
    globalerror=$error
    ((failures++))
    ((totalTests++))
    fi
    echo ""
}

while getopts kdpsh c; do
    case $c in
    k) # Keep intermediate files
        keep=1
        ;;
    h) # Help
        Usage
        ;;
    esac
done

shift `expr $OPTIND - 1`

if [ $# -ge 1 ]
then
    files=$@
else
    files="tests/test-*.bd"
fi

for file in $files
do
    case $file in
    *test-*)
        Check $file 2>> $globallog
        ;;
    *fail-*)
        CheckFail $file 2>> $globallog
        ;;
    *)
        echo "unknown file type $file"
        globalerror=1
        ;;
    esac
done

echo "successes = $successes"
echo "failures = $failures"
echo "total tests = $totalTests"

exit $globalerror

#!/usr/bin/bash

#bashdb - a bash debugger

########################
###---DRIVER SCRIPT---##
########################

#Driver Script: concatenates the preamble and the target script
#and then executes the new script

echo 'bash Debugger version 1.0"

#bashdb takes as the first argument the name of the guinea  pig file. 
_dbname=${0##*/}

#Any subsequent arguments are passed on to the guinea pig as positional parameters
if (( $# < 1 )) ; then
    echo "$_dbname: Usage: $_dbname filename" >&2
    exit 1
fi
_guineapig=$1

#If no arguments are given, bashdb prints out a usage line and exits with an error status
if [ ! -r $1 ]; then
    echo "$db_name: Cannot read file ' $_guineapig'." >&2
    exit 1
fi

#If all is in order, bashdb constructs a temporary file 
shift
_tmpdir=/tmp
_libdir=.
_debugfile=$_tmpdir/bashdb.$$ #temporary file for script that is being debugged
cat $_libdir/bashdb.pre $_guineapig > $_debugfile

#The last line runs the newly created script with exec
#simply runs the newly constructed shell sript in another shell, passing the new script three arguments--
#the name of the original guinea pig file ($_guineapig), the name of the temporary directory ($_tmpdir), and the name of the library directory ($_libdir)
#followed by the users' positional parameters, if any
exec bash $_debugfile $_guineapig $_tmpdir $_libdir "$@"


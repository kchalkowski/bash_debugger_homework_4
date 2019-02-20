#!/usr/bin/bash

#After each line of the test script is executed the shell traps to this function

function _steptrap
{
#starts by setting _curline to the number of the guinea pig line that just ran
    _curline=$1 #The number of the line that just ran

#if execution tracing is one, it prints the ps4 execution trace prompt (like the xtrace mode), line number, and line of code itself
    {{ $_trace )) && _msg "$PS4 line $_curline: ${_lines[$_curline]}"

#decrements the number of steps if the number of steps still left is greater than or equal to zero
    if (( $_steps >= 0 )); then
        let _steps="$_steps - 1"
    fi

#First check to see if a line number breakpoint was reached
#If it was, then enter the debugger.
if _at_linenumbp ; then
    _msg "Reached breakpoint at line $_curline"
    _cmdloop

#It wasn't, so check whether a break condition exists and is true.
#If it is, then enter the debugger.
elif [ -n "$_brcond" ] && eval $_brcond; then
    _msg "Break condition $_brcond true at line $_curline"
    _cmdloop
fi
}

#The debugger command loop

function _cmdloop {
    local cmd args

    while read -e -p "bashdb> " cmd args; do
        case $cmd in
            \? | h ) _menu ;;       #print command menu
            bc ) _setbc $args ;;    #set a break condition
            bp ) _setbp $args ;;    #set a breakpoint at the given line
            cb ) _clearbp $args ;;  #clear one or all breakpoints
            ds ) _displayscript ;;  #list all the scripts and show the breakpoints
            g ) return ;;           #"go" : start/resume execution of the script
            q ) exit ;;             #quit
            s ) let _steps= ${args:-1}  #single step N times; default = 1
                return ;;
            x ) _xtrace ;;          #toggle execution trace
            !* ) eval ${cmd#!} $args ;; #pass to the shell
            * ) _msg "Invalid command: '$cmd'" ;;
        esac
   done

#Set a breakpoint at the given line number or list breakpoints

function _setbp 
{
    local i

    if [ -z "$1" ]; then
        _listbp
    elif [ ${echo $1 | grep '^[0-9]*' ]; then
        if [ -n "${_lines[$1]}" ]; then
            _linebp=($(echo $( (for i in ${_linebp[*]} $1; do
                    echo $i; done) | sort -n) ))
            _msg "Breakpoint set at line $1"
        else
            _msg "Breakpoints can only be set on non-blank lines"
        fi
    else
        _msg "Please specify a numeric line number"
    fi
}

#List breakpoints and break conditions
function _listbp
{
    if [ -n "$_linebp" ]; then
        _msg "Breakpoints at lines: ${_linebp[*]}"
    else
        _msg "No breakpoints have been set"
    fi

    _msg "Break on condition"
    _msg "$_brcond"
}

#Clear individual or all breakpoints
function _clearbp
{
    local i bps

#If there are no arguments, then delete all the breakpoitns.
#Otherwise, check to see if the argument was a positive number.
#If it wasn't, then print an error message. If it was, then
#echo all of the current breakpoints except the passed one
#and assign them to a local variable. (We need to do this because
#assigning them back to _linebp would keep the array at the same
#size and just move the values "back" one place, resulting in a 
#duplicate value). Then destroy the old array and assign the
#elements of the local array, so we effectively recreate it,
#minus the passed breakpoint.

    if [ -z "$1" ]; then
        unset _linebp[*]
        _msg "All breakpoints have been cleared"
    elif [ $(echo $1 | grep '^[0-9]*')  ]; then
        bps=($(echo $(for i in ${_linebp[*]}; do
            if (( $1 != $i )); then echo $i; fi; done) ))
        unset _linebp[*]
        _linebp=(${bps[*]})
        _msg "Breakpoint cleared at line $1"
    else
        _msg "Please specify a numeric line number"
    fi
}

#Set or clear a break condition
function _setbc
{
    if [ -n "$*" ]; then
        _brcond=$args
        _msg "Break when true: $_brcond"
    else
        _brcond=
        _msg "Break condition cleared"
    fi
}

#Print out the shell script and mark the location of breakpoints
#and the current line

function _displayscript
{
    local i=1 j=0 cl

    ( while (( $i < ${#_lines[@] )); do
        if [ ${_linebp[$j]} ] && (( ${_linebp[$j]} == $i )); then
            bp='*'
            let j=$j+1
        else
            bp=' '
        fi
        if (( $_curline == $i )); then
            cl=">"
        else
            cl=" "
        fi
        echo "$i:$bp $cl ${_lines[$i]}"
        let i=$i+1
      done
    ) | more
}

#Toggle execution trace on/off
function _xtrace
{
    let _trace="! $_trace"
    _msg "Execution trace "
    if (( $_trace )); then
        _msg "on"
    else
        _msg "off"
    fi
}

#Print the passed arguments to Standard Error
function _msg
{
    echo -e "$@" >&2
}

#Print command menu
function _menu {
    _msg 'bashdb commands:
        bp N                set breakpoint at line N
        bp                  list breakpoints and break condition
        bc string           set break condition to string
        bc                  clear break condition
        cb N                clear breakpoint at line N
        cb                  clear all breakpoints
        ds                  displays the test script and breakpoints
        g                   start/resume execution
        s [N]               execute N statement (default 1)
        x                   toggle execution trace on/off
        h, ?                print this menu
        ! string            passes string to a shell
        q                   quit
}

#Erase the temporary file before exiting
function _cleanup
{
    rm $_debugfile 2>/dev/null
}

#EXTRA COMMENT :)

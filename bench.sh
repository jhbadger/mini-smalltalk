#!/bin/bash
# bench.sh - micro-benchmarks for the VM.  Usage: ./bench.sh [path/to/st]   (default ./st)
# Each line prints the best of 3 runs in milliseconds.
ST=${1:-./st}
t() {
    best=
    for i in 1 2 3; do
        ms=$($ST -c /dev/null -e "$2" 2>&1 | tail -1 | tr -dc '0-9')
        [ -z "$ms" ] && { echo "$1: FAILED"; return; }
        if [ -z "$best" ] || [ "$ms" -lt "$best" ]; then best=$ms; fi
    done
    printf '%-28s %6s ms\n' "$1" "$best"
}
FIB="Object subclass: #Fib instanceVariableNames: '' classVariableNames: '' category: 'bench'. Fib compile: 'fib: n ^n < 2 ifTrue: [n] ifFalse: [(self fib: n - 1) + (self fib: n - 2)]'. "
t "arith loop 5M"      "Time millisecondsToRun: [ | x | x := 0. 1 to: 5000000 do: [:i | x := x + (i \\\\ 7)] ]"
t "fib 32 (sends)"     "${FIB}Time millisecondsToRun: [Fib new fib: 32]"
t "timesRepeat 3M"     "Time millisecondsToRun: [ | x | x := 0. 3000000 timesRepeat: [x := x + 1] ]"
t "block value: 2M"    "Time millisecondsToRun: [ | b x | x := 0. b := [:i | x := x + i]. 1 to: 2000000 do: [:i | b value: i] ]"
t "Array do: 2M"       "Time millisecondsToRun: [ | a s | a := Array new: 2000000 withAll: 1. s := 0. a do: [:e | s := s + e] ]"
t "Array at:put: 2M"   "Time millisecondsToRun: [ | a | a := Array new: 1000. 1 to: 2000000 do: [:i | a at: i \\\\ 1000 + 1 put: i] ]"
t "OC printString 300k" "Time millisecondsToRun: [ | oc | oc := OrderedCollection new. 1 to: 300000 do: [:i | oc add: i printString] ]"
t "Dictionary 100k"    "Time millisecondsToRun: [ | d | d := Dictionary new. 1 to: 100000 do: [:i | d at: i put: i]. 1 to: 100000 do: [:i | d at: i] ]"
t "sort 100k"          "Time millisecondsToRun: [ ((1 to: 100000) asArray collect: [:i | (i * 7919) \\\\ 100003]) asSortedCollection: [:a :b | a < b] ]"
t "live heap + garbage"  "Time millisecondsToRun: [ | keep | keep := (1 to: 400000) asOrderedCollection collect: [:i | i printString]. 1 to: 1500000 do: [:i | i printString] ]"

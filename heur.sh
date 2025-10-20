#!/bin/bash
set -e

make make_input
x=10000000
while true; do
    echo "tester med x: $x"
    echo "let x = ${x}i64" > heuristik.fut
    futhark bench --backend=cuda auto_test.fut
    sleep 2
    ((x=(10*x/13)/10))
done

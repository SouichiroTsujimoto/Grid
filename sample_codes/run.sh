#!/bin/bash

cd ..
nimble build
bin/grid sample_codes/main.grid -o sample_codes/main.cpp -ast
cd sample_codes
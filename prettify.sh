#!/bin/bash
for file in *.{s,inc,vasm}
do
   if  [ -f $file ]
   then     
	pretty6502/pretty6502  -l -ml -dl $file $file
   fi
done

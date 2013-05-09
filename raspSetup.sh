#!/bin/bash

if (( $#<1 )); then
	echo You have to give the number of process...
	exit 1
fi 

nbP=$1

echo starting $nbP raspbuddies clients...

for ((i = 1; i <= $nbP; i += 1 )) do
	echo -e "\t starting $i process..."
	ruby ForRasp/raspbuddies.rb $i > trace$i.txt &
done

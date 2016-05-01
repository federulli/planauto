#!/bin/bash

echo Novedades:
for archivo in `ls ../novedades`; do
	#cant=`wc -l ../novedades/$archivo`
	p=`wc -l ../novedades/$archivo | sed "s/^\([0-9]*\).*$/\1/"`
	echo $archivo $p
done
echo Mestros:
for archivo in `ls ../maestros`; do
	p=`wc -l ../maestros/$archivo | sed "s/^\([0-9]*\).*$/\1/"`
	echo $archivo $p
done

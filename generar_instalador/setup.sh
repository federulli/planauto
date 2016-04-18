#!/bin/bash

for targzfile in `ls | grep "^[^.]*.tar.gz$"`; do
	# Descomprimo 	
	tar -zxvf $targzfile
	# Borro el archivo tar.gz
	rm $targzfile
done

for gzfile in `ls | grep "^[^.]*.gz$"`; do
	echo $gzfile
done


#!/bin/bash

for targzfile in `ls | grep "^[^.]*.tar.gz$"`; do
	# Descomprimo 	
	tar -zxvf $targzfile
	# Borro el archivo tar.gz
	rm $targzfile
done

gzip -d *.gz

chmod +x generar_config.sh
./generar_config.sh
 
mkdir aceptados

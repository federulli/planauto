#!/bin/bash

#comprimo directorios
salida=`pwd`/GRUPO04
if [ -d $salida ]; then
	 rm -r $salida
fi
mkdir $salida

old_ifs=$IFS
IFS=','
for directorio in `cat directorios.ini`
do
	if [ -d ../$directorio ]; then
		echo "comprimiendo $directorio.."
		tar -zcvf $salida/$directorio.tar.gz ../$directorio 2> /dev/null 1> /dev/null
		
	else
		echo "No se encuentra el directorio $directorio"
	fi
done

# Comprimo archivos con gzip
for archivo in `cat archivos.ini`
do
	if [ -f ../$archivo ]; then
		echo "comprimiendo $archivo"
		gzip -k -c ../$archivo  > $salida/$archivo.gz
	else
		echo "No se encuentra el archivo $archivo"
	fi 

done 

# Agrego setup.sh
cp setup.sh ./GRUPO04/
# Creo el archivo instalador.tgz

if [ -d $salida ]; then
	tar -cvzf instalador.tgz GRUPO04
else 
	echo Error al crear instalador.tgz no se encuentra la carpeta GRUPO04
	exit
fi
rm -r $salida 

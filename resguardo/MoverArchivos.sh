#!/bin/bash

if (( $# < 2 )) ; then
	$BINDIR/GrabarBitacora.sh "MoverArchivos" "Cantidad de parametros incorrecta" "ERR"
	exit
fi

origen="$1"
destino="$2"
comando="$3"

if [ -z $comando ]; then
	comando="MoverArchivos"
fi
if [ $origen == $destino ]; then
	$BINDIR/GrabarBitacora.sh "$comando" "Origen y Destino iguales" "ERR"
	exit
fi	

if [ ! -f $origen ]; then
	$BINDIR/GrabarBitacora.sh "$comando" "No existe el archivo origen" "ERR"
	exit
fi

directorio_destino=`echo $destino | sed "s-\([^/]*/*\)\([^/]*\.[^/\.]*$\)-\1-g"`
if [ ! -d $directorio_destino ]; then
	echo $directorio_destino
	$BINDIR/GrabarBitacora.sh "$comando" "No existe el directorio destino" "ERR"
	exit
fi
nombre_archivo=`echo $destino | grep "[^/]*/*[^/]*\.[^/\.]*$"`
if [ ! -z $nombre_archivo ]; then
	nombre_archivo=`echo $nombre_archivo | sed "s-/*\([^/]*/\)*\([^/\.]*\.[^\./]\)-\2-g"`
fi

if [ -z $nombre_archivo ]; then
	#nombre_archivo=`echo $origen | grep "[^/]*/*[^/]*\.[^/\.]*$"`
	nombre_archivo=`echo $origen | sed "s-/*\([^/]*/\)*\([^/]*$\)-\2-g"`
fi

if [ ! -f "$directorio_destino/$nombre_archivo" ]
	then
		mv $origen $destino
		exit
	else	
		# si ya existe el archivo en la carpeta destino lo agrego en la carpeta destino/dpl/ 
		duplicado="$directorio_destino/dpl/$nombre_archivo"
		cantidad=0
		archivo_copia="$duplicado$cantidad"
		# si no existe /dpl la creo
		if [ ! -d "$directorio_destino/dpl" ]; then
				mkdir "$directorio_destino/dpl"
		fi
		# voy desde 0 a n buscando un nombre de archivo q no exista
		while [ -f $archivo_copia ]; do
			cantidad=$(( $cantidad + 1 ))
			archivo_copia="$duplicado$cantidad"
		done
		mv $origen $archivo_copia
fi

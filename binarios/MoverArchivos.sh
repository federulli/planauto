#!/bin/bash

if (( $# < 2 )) ; then
	$BINDIR/GrabarBitacora.sh "MoverArchivos" "Cantidad de parametros incorrecta" "ERR"
	exit
fi

origen="$1"
destino="$2"
comando="$3"

if [ $origen == $destino ]; then
	$BINDIR/GrabarBitacora.sh "$comando" "Origen y Destino iguales" "ERR"
	exit
fi	

if [ ! -f $origen ]; then
	$BINDIR/GrabarBitacora.sh "$comando" "No existe el archivo origen" "ERR"
	exit
fi


if [ ! -d $destino ]; then
	#saco el nombre del archivo para ver si existe el directorio
	directorio_destino=`echo $destino | sed "s-\([^/]*/*\)\([^/]*$\)-\1-g"`
	if [ ! -d $directorio_destino ]; then
		$BINDIR/GrabarBitacora.sh "$comando" "No existe el directorio destino" "ERR"
		exit
	fi
else
	directorio_destino=$destino
fi

if [ ! -f $destino ]
	then
		mv $origen $destino
		exit
	else	
		# si ya existe el archivo en la carpeta destino lo agrego en la carpeta destino/dpl/ 
		duplicado=`echo $destino | sed "s-\([^/]*/*\)\([^/]*$\)-\1dpl/\2-g"`
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

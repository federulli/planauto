#!/bin/bash

function GrabarBitacora {

	if (( $# < 2 ))
		then
			GrabarBitacora "GrabarBitacora" "Cantidad de parametros incorrectos" "ERR"
			return 1	
	fi

	local comando=$1
	local mensaje=$2
	if [ $# -lt 3  -o "$3" == "" ]
		then
			local info="INFO"
		else	
			if [ "$3" == "INFO" -o "$3" == "WAR" -o "$3" == "ERR" ]; then
				info=$3
			else	
		 		GrabarBitacora "GrabarBitacora" "Tipo de mensaje incorrecto" "ERR" 
				return 1
			fi
	fi

	local file="$LOGDIR/$comando.log"

	local lineas=0
	# Calculo cantidad de lineas
	if [ -f $file ] ; then
		lineas=`wc -l $file | sed "s/^\([0-9][0-9]*\)\(.*\)/\1/g"`
	fi 

	# Si la cantidad de lineas es mayor al tamaño maximo de log trunco
	if (( $lineas > $LOGSIZE )); then
		# setear la cantidad lineas de archivo config 
		aux=`cat $file | tail -n2`
		>$file
		GrabarBitacora "$comando" "Log Excedido"
		echo $aux >> $file
	fi
	echo "$USER-`date`-$comando-$info-$mensaje" >> $file
	return 0
}

GrabarBitacora "$@"

#!/bin/bash

# parametro nombre del proceso a detener sin .sh

script_padre="stop" #El demonio necesita saber si va a ser iniciado o detenido, esta variable cumple esa funcion
export script_padre

if [ $# -lt 1 ]; then
	echo "Falta indicar el nombre del proceso a detener"
	exit
fi

nombre=`echo $1 | sed "s/\([^\.]*\).*/\1.sh/g"`
pid=`pidof -x $nombre`
if ! [ -z $pid ]; then
	kill "$pid"
	echo "$nombre detenido"
else
	echo "$nombre no esta en ejecucion"
fi


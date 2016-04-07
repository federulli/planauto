#!/bin/bash

# parametro nombre del proceso a detener sin .sh

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


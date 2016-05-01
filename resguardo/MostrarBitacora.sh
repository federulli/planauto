#!/bin/bash


function MostrarBitacora {


 	if [ $# -eq 0 ]; then
		echo "falta parametros";
		return 1
	fi
	
	local comando=$1;
	local file="$LOGDIR/$comando.log";

	if [ ! -f $file ]; then
		echo "el archivo deseado no existe";
		return 1
	fi
	
	if [ $# -eq 1 ]; then
		cat $file;
	elif [ $# -eq 2 ]; then
		docu=`cat $file | grep "$2"`
		viejo=$IFS
		IFS="
"
		i=0
		for linea in $docu
		do
			echo $linea
			let i=i+1
		done
		echo "$i elementos"
		IFS=$viejo

		return 0
	elif [ "$3" == "usuario" ]; then 
		
		viejo=$IFS
		IFS="
	"
		docu=`cat $file|grep "^.*$2.*-"`
		i=0
		for linea in $docu
		do
			echo $linea
			let i=i+1						
		done
			echo "$i elementos"
			IFS=$viejo

		return 0
	elif [ "$3" == "fecha" ]; then 
		
		viejo=$IFS
		IFS="
	"
		docu=`cat $file|grep "^[^-]*-.*$2.*-"`
		i=0
		for linea in $docu
		do
			echo $linea
			let i=i+1						
		done
			echo "$i elementos"
			IFS=$viejo

		return 0
	elif [ "$3" == "comando" ]; then 
		
		viejo=$IFS
		IFS="
	"
		docu=`cat $file|grep "^[^-]*-[^-]*-.*$2.*-"`
		i=0
		for linea in $docu
		do
			echo $linea
			let i=i+1						
		done
			echo "$i elementos"
			IFS=$viejo

		return 0
	elif [ "$3" == "typo" ]; then 
		
		viejo=$IFS
		IFS="
	"
		docu=`cat $file|grep "^[^-]*-[^-]*-[^-]*-.*$2.*-"`
		i=0
		for linea in $docu
		do
			echo $linea
			let i=i+1						
		done
			echo "$i elementos"
			IFS=$viejo

		return 0
	elif [ "$3" == "mensaje" ]; then 
		
		viejo=$IFS
		IFS="
	"
		docu=`cat $file|grep "^[^-]*-[^-]*-[^-]*-[^-]*-.*$2.*"`
		i=0
		for linea in $docu
		do
			echo $linea
			let i=i+1						
		done
			echo "$i elementos"
			IFS=$viejo

		return 0
	else
		echo "el tercero parametro tiene que ser igual a usuario, fecha, typo, mensaje o comando"
		return 1		
	fi
	
}

MostrarBitacora "$@"

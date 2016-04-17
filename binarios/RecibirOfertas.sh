#!/bin/bash

function rechazarArchivo {
	#Si no existe la carpeta de rechazados la creo
	if [ ! -d "$NOKDIR" ]; then
		mkdir "$NOKDIR"
	fi
				
	$BINDIR/MoverArchivos.sh "$ARRIDIR/$1" "$NOKDIR" "RecibirOfertas"
}

function aceptarArchivo {
	#Si no existe la carpeta de aceptados la creo
	if [ ! -d "$OKDIR" ]; then
		mkdir "$OKDIR"
	fi
	
	$BINDIR/MoverArchivos.sh "$ARRIDIR/$1" "$OKDIR" "RecibirOfertas"
}

function validarFecha {
	fecha=`echo $1 | sed "s-\([^_]*\)_\(.*\)-\2-"`
	echo $fecha 
}

function validarConcesionario {
	encontrado=false	
	concesionario=`echo $1 | sed "s-\([^_]*\)_\(.*\)-\1-"` 	
	cantidadDeConcesionarios=`echo $2 | wc "-w"`
	i="0"

	while (( "$encontrado" != true )) || (( $i < $cantidadDeConcesionarios )); do
		for id in $2; do
			if [ $id = $concesionario ]; then
				encontrado=true
			fi
			i=$[$i+1]
		done
	done 


	if [ "$encontrado" = true ]; then
		#validarFecha $1 #$1=Nombre de fichero
		echo "Lo encontre!"
		return 0 #esto se tiene que borrar cuando este validar fecha
	else
		return 1
	fi	
}

function validar {
	#Hago la validacion por partes, primero me encargo de la extension
	if [ $1 = "csv" ]; then
		validarConcesionario "$2" "$3" #$2=Nombre de fichero, $3=Lista de concesionarios
	else
		return 1
	fi
}

function recorrerArchivos {
	files=`ls $ARRIDIR` 
	for file in $files ; do
		extension_fichero=`echo $file | sed "s-[^.]*\.\(.*\)-\1-"`
		nombre_fichero=`echo $file | sed "s-\([^.]*\)\.\(.*\)-\1-"`
		validar $extension_fichero $nombre_fichero "$1"
		
		if [ $? = 0 ]; then
			aceptarArchivo $file
				
		else
			rechazarArchivo $file
		fi
       	done
}

start(){
	#Creo la lista de concesionarios
	lista=`cat $MAEDIR/concesionarios.csv | grep "^[^;]*;[^;]*$" | sed "s-[^;]*;\(.*\)-\1-"`

	recorrerArchivos "$lista"
	
	#sleep 10
	#start

	RETVAL=$?
	echo
}
 
stop(){
	echo -n $"Stopping service: "

	RETVAL=$?
	echo
}
 
restart(){
	stop
	sleep 10
	start
}
 
# Dependiento del parametro que se le pase
#start - stop - restart ejecuta la función correspondiente.
case "$script_padre" in
start)
 start
 ;;
stop)
 stop
 ;;
restart)
 restart
 ;;
*)
 exit 1
esac
 
exit 0

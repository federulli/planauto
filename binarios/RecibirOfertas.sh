#!/bin/bash

function validarNombre {
echo "esta es mi variable $1"
	sucursal=`echo $1 | sed "s-\([^_]*\)_\(.*\)-\1-" ` 
	echo $sucursal
	segunda=`echo $1 | sed "s-\([^_]*\)_\(.*\)-\2-"`
	echo $segunda 

}

function validarExtension {
	if [ $1 = "csv" ]; then
		return 0
	else
		return 1
	fi
}

function recorrerArchivos {
	files=`ls $ARRIDIR` 
	for file in $files ; do
		extension_fichero=`echo $file | sed "s-[^.]*\.\(.*\)-\1-"`
		nombre_fichero=`echo $file | sed "s-\([^.]*\)\.\(.*\)-\1-"`
		validarExtension $extension_fichero $nombre_fichero
		
		if [ $? = 0 ]; then
			validarNombre $nombre_fichero
		else	
			#Si no es un archivo de extension valida lo muevo			
			$BINDIR/MoverArchivos.sh "$ARRIDIR/$file" "$NOKDIR" "RecibirOfertas"
		fi

		#test
		echo $extension_fichero
		echo $nombre_fichero
       	done

}

start(){
	recorrerArchivos
	sleep 10
	start

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

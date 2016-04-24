#!/bin/bash

function rechazarArchivo {
	#Si no existe la carpeta de rechazados la creo
	if [ ! -d "$NOKDIR" ]; then
		mkdir "$NOKDIR"
	fi
				
	$BINDIR/MoverArchivos.sh "$ARRIDIR/$1" "$NOKDIR" "RecibirOfertas"
}

function aceptarArchivo {
	#Si el archivo esta vacio, de cualquier forma se rechaza
	if [ -s $ARRIDIR/$1 ]; then

		#Si no existe la carpeta de aceptados la creo
		if [ ! -d "$OKDIR" ]; then
			mkdir "$OKDIR"
		fi

		$BINDIR/MoverArchivos.sh "$ARRIDIR/$1" "$OKDIR" "RecibirOfertas"
	else
		rechazarArchivo $1
	fi		
}

function validarFecha {
	#ULTIMO ACTO DE ADJUDICACION ES UNA CONSTANTE SOLO PARA TESTEAR Y PORQUE FALTA ESTE SCRIPT!!!
	#ULTIMO ACTO DE ADJUDICACION ES UNA CONSTANTE SOLO PARA TESTEAR Y PORQUE FALTA ESTE SCRIPT!!!
	#ULTIMO ACTO DE ADJUDICACION ES UNA CONSTANTE SOLO PARA TESTEAR Y PORQUE FALTA ESTE SCRIPT!!!
	ultimaAdjudicacion="19910514"
	#ULTIMO ACTO DE ADJUDICACION ES UNA CONSTANTE SOLO PARA TESTEAR Y PORQUE FALTA ESTE SCRIPT!!!
	#ULTIMO ACTO DE ADJUDICACION ES UNA CONSTANTE SOLO PARA TESTEAR Y PORQUE FALTA ESTE SCRIPT!!!
	#ULTIMO ACTO DE ADJUDICACION ES UNA CONSTANTE SOLO PARA TESTEAR Y PORQUE FALTA ESTE SCRIPT!!!

	fecha=`echo $1 | sed "s-\([^_]*\)_\(.*\)-\2-"`

	date --date $fecha >/dev/null 2>&1 #Oculto salida estandar y error
	if [ $? = 0 ]; then
		fechaDeHoy=`date +%Y%m%d`
		calculoDiaActual=$[$fechaDeHoy-$fecha]
		calculoDiaAdjudicacion=$[$fecha-$ultimaAdjudicacion]
		if [ $calculoDiaActual -ge "0" ] && [ $calculoDiaAdjudicacion -gt "0" ]; then #-ge: mayor o igual a...
			return 0
		fi
	else
		#Fecha invalida		
		return 1
	fi
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
		validarFecha $1 #$1=Nombre de fichero
	else
		#No existe concesionario
		return 1
	fi	
}

function validar {
	#Hago la validacion por partes, primero me encargo de la extension
	if [ $1 = "csv" ]; then
		validarConcesionario "$2" "$3" #$2=Nombre de fichero, $3=Lista de concesionarios
	else
		#Extension invalida
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

function verificarNovedadesPendientes {
	#Si la carpeta tiene archivos sin procesar, invoco ProcesarOfertas.sh
	cantFicheros=`ls "$OKDIR" | wc -l`

	if [ $cantFicheros != "0" ]; then
			$BINDIR/LanzarProceso.sh "ProcesarOfertas" "F"
	fi
}

start(){
	#Creo la lista de concesionarios
	lista=`cat $MAEDIR/concesionarios.csv | grep "^[^;]*;[^;]*$" | sed "s-[^;]*;\(.*\)-\1-"`

	#Si no existe la carpeta de arribados la creo
	if [ ! -d "$ARRIDIR" ]; then
			mkdir "$ARRIDIR"
	fi

	#Si la carpeta tiene archivos sin procesar, ejecuta recorrerArchivos
	cantFicheros=`ls "$ARRIDIR" | wc -l`

	if [ $cantFicheros != "0" ]; then
		recorrerArchivos "$lista"
	fi

	#Verificar si hay Novedades Pendientes
	verificarNovedadesPendientes

	#sleep $SLEEPTIME
	#start

	RETVAL=$?
}
 
stop(){
	echo -n $"Servicio detenido: "

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

#!/bin/bash

function rechazarArchivo {
	#Si no existe la carpeta de rechazados la creo
	if [ ! -d "$NOKDIR" ]; then
		mkdir "$NOKDIR"
	fi
				
	$BINDIR/MoverArchivos.sh "$ARRIDIR/$1" "$NOKDIR" "RecibirOfertas"
	$BINDIR/GrabarBitacora.sh "RecibirOfertas" "Se rechaza el archivo $1. $2" #$2 Es el motivo
}

function aceptarArchivo {
	#Si el archivo esta vacio, de cualquier forma se rechaza
	if [ -s $ARRIDIR/$1 ]; then
		$BINDIR/MoverArchivos.sh "$ARRIDIR/$1" "$OKDIR" "RecibirOfertas"
	else
		rechazarArchivo $1 "El archivo esta vacio."
	fi		
}

function ultimaFechaDeAdj {
	#Todos los meses se hace un acto, por ende, tomo la fecha que corresponde al mes anterior del actual
	#como ultima fecha de adjudicacion

	mesUltimoActo=`date +%m --date='-1 month'`
	fecha=`cat $MAEDIR/FechasAdj.csv | grep "[0-9][0-9]/$mesUltimoActo" | sed "s-\([^;]*\).*-\1-"`

	#Fecha valida es en formato aaaammdd
	fechaValida=`echo $fecha | sed "s-\([^\/]*\)\/\([^\/]*\)\/\([^\/]*\).*-\3\2\1-"`
}

function validarFecha {
	ultimaFechaDeAdj	
	ultimaAdjudicacion=$fechaValida
	fecha=`echo $1 | sed "s-\([^_]*\)_\(.*\)-\2-"`

	date --date $fecha >/dev/null 2>&1 #Oculto salida estandar y error
	if [ $? = 0 ]; then
		fechaDeHoy=`date +%Y%m%d`
		calculoDiaActual=$[$fechaDeHoy-$fecha]
		calculoDiaAdjudicacion=$[$fecha-$ultimaAdjudicacion]
		if [[ $calculoDiaActual -ge 0 ]] && [[ $calculoDiaAdjudicacion -gt 0 ]]; then #-ge: mayor o igual a... -gt mayor a...
			return 0
		else
			motivo="La fecha en el nombre de archivo no es menor o igual a la fecha actual o no es mayor a la fecha del ultimo acto de adjudicacion"
			return 1
		fi

	else
		#Fecha invalida	
		motivo="La fecha en el nombre del archivo no es valida"	
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
		motivo="No existe concesionario"
		return 1
	fi	
}

function validar {
	#Hago la validacion por partes, primero me encargo de la extension
	if [ $1 = "csv" ]; then
		validarConcesionario "$2" "$3" #$2=Nombre de fichero, $3=Lista de concesionarios
	else
		#Extension invalida
		motivo="Extension invalida"
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
			rechazarArchivo $file "$motivo"
		fi
       	done
}

function verificarNovedadesPendientes {
	#Si no existe la carpeta de aceptados la creo
	if [ ! -d "$OKDIR" ]; then
		mkdir "$OKDIR"
	fi

	#Si la carpeta tiene archivos sin procesar, invoco ProcesarOfertas.sh
	cantFicheros=`ls "$OKDIR" | wc -l`

	if [ $cantFicheros != "0" ]; then
		#Si el proceso se encuentra en ejecucion grabo el log
		if ! [ -z `pidof -x ProcesarOfertas.sh` ]; then
			$BINDIR/GrabarBitacora.sh "RecibirOfertas" "Invocacion de ProcesarOfertas pospuesta para el siguiente ciclo."
		else
			#Lo ejecuto en B para que RecibirOfertas siga trabajando
			$BINDIR/LanzarProceso.sh "ProcesarOfertas" "B"
		fi
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

	sleep $SLEEPTIME
	$BINDIR/GrabarBitacora.sh "RecibirOfertas" "Ciclo nro. $ciclo"
	ciclo=$((ciclo+1))
	start

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
	ciclo=0
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

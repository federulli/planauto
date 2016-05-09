#!/bin/bash
function validarArchivo {
#verifico que el archivo exista y no este vacio
	if [ ! -f "$MAEDIR/FechasAdj.csv" ]; then
		$BINDIR/GrabarBitacora.sh "GenerarSorteo" "No existe archivo de adjudicaciones" "ERR"		
		exit 1
	else
		if [ ! -s "$MAEDIR/FechasAdj.csv" ]; then
		$BINDIR/GrabarBitacora.sh "GenerarSorteo" "El archivo de adjudicaciones esta vacio" "ERR"
		exit 1
		fi
	fi		
}

function iniciarLog {
	$BINDIR/GrabarBitacora.sh "GenerarSorteo" "Inicio de Sorteo"
}

function finalizarLog {
	$BINDIR/GrabarBitacora.sh "GenerarSorteo" "Fin de Sorteo"
}

function verificarDirectorios {
#verifico si existe la carpeta de ofertas procesadas y la de sorteos
#si falta alguna las creo	
	if [ ! -d "$PROCDIR" ]; then
		mkdir "$PROCDIR"
	fi

	if [ ! -d "$PROCDIR/sorteos" ]; then
			mkdir "$PROCDIR/sorteos"	
	fi 		
}

function realizarSorteo {
	seguir=true
	fechaActual=$(date +%Y%m%d)

	while IFS='' read -r linea && [ $seguir = true ]; do	
	    #obtengo la fecha de adjudicacion en formato dd/mm/aaaa y la paso a aaaammdd
		fechaAdjudicacion=`echo $linea | sed "s-\([0-9]*\).\([0-9]*\).\([0-9]*\).*-\3\2\1-"`
		#verifico que sea una fecha valida
		date --date $fechaAdjudicacion >/dev/null 2>&1 #Oculto salida estandar y error
		if [ $? = 0 ]; then
			if  [ $fechaActual -le $fechaAdjudicacion ]; then
			seguir=false		
			fi
		else
			$BINDIR/GrabarBitacora.sh "GenerarSorteo" "El archivo maestro de adjudicaciones presenta la siguiente fecha de adjudicacion invalida $linea " "WAR"
		fi		
	done < "$MAEDIR/FechasAdj.csv"

	if [ $seguir = true ]; then
		$BINDIR/GrabarBitacora.sh "GenerarSorteo" "No hay fechas de adjudicacion posteriores al dia de la fecha" "ERR"
		exit 1
	fi

	cantidadDeSorteos=`ls "$PROCDIR/sorteos" | wc -l`
	if [ $cantidadDeSorteos -eq 0 ]; then
		sorteoId=1
	else
		sorteoId=$((cantidadDeSorteos+1))
	fi

	rutaArchAdjudicaciones="${PROCDIR}/sorteos/${sorteoId}_${fechaAdjudicacion}.srt"
	primerNumeroSorteo=1
	ultimoNumeroSorteo=168
	numeroDeOrden=1
	numerosDeSorteo=$( shuf -i $primerNumeroSorteo-$ultimoNumeroSorteo ) #random de los numeros de sorteo

	for numero in $numerosDeSorteo; do
		echo "$(printf "%03d\n" $numeroDeOrden);$numero" >> $rutaArchAdjudicaciones
		let "numeroDeOrden= numeroDeOrden+1"
	done
	$BINDIR/GrabarBitacora.sh "GenerarSorteo" "Se realizo el sorteo con id $sorteoId" 	
}
iniciarLog
validarArchivo
verificarDirectorios
realizarSorteo
finalizarLog

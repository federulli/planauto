#!/bin/bash

function validarArchivo {

#primero verifico el nombre
	archivo="$1"
	if [ "$archivo" != "FechasAdj.csv" ]; then
	#	$BINDIR/GrabarBitacora.sh "GenerarSorteo" "Nombre de archivo de adjudicacion invalido" "ERR"
		exit 1
	fi		
#verifico que el archivo exista y no este vacio
	if [ ! -f "$archivo" ]; then
	#	$BINDIR/GrabarBitacora.sh "GenerarSorteo" "No existe archivo de adjudicaciones" "ERR"		
		exit 1
	else
		if [ ! -s "$archivo" ]; then
	#	$BINDIR/GrabarBitacora.sh "GenerarSorteo" "El archivo de adjudicaciones esta vacio" "ERR"
		exit 1
	fi	
	echo "paso todas las validaciones"	
}

function verificarParametros {
	if [ $# -lt 1 ]; then
#		$BINDIR/GrabarBitacora.sh "GenerarSorteo" "Cantidad de parametros incorrecta" "ERR"
		echo "cantidad de parametros incorrecta"
		exit 1
	else
		echo "paso la verificacion de parametros"
		validarArchivo "$1"
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
	else
		if [ ! -d "$PROCDIR/sorteos" ]; then
			mkdir "$PROCDIR/sorteos"
		fi
	fi 		
}

function realizarSorteo {
#TODO determinar como obtener fecha de adjudicacion
#TODO verificar si hay otros sorteos en la misma fecha y ajustar el id 

	fechaAdjudicacion="19910514"
	sorteoId="01"
	rutaArchAdjudicaciones="${$PROCDIR}/sorteos${sorteoId}_${fechaAdjudicacion}"

	primerNumeroSorteo= 1
	ultimoNumeroSorteo= 168
	contador= 1
	numerosDeSorteo= $( shuf -i $primerNumeroSorteo-$ultimoNumeroSorteo ) #random de los numeros de sorteo

	for numero in numerosDeSorteo; do
		echo "Numero de orden $contador le corresponde el numero de sorteo $valor" >> $rutaArchAdjudicaciones
		let "contador= contador+1"
	done
}

verificarParametros "$@"
echo "termino las validaciones"
iniciarLog
verificarDirectorios
realizarSorteo "$1"
finalizarLog

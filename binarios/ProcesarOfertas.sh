#!/bin/bash

#Los archivos adentro tienen:
# 7 caracteres, los primeros 4 corresponen al numero de grupo,
# los siguientes 3 al numero de orden de suscriptor dentro del grupo.
#Luego del ; el importe que se ofrece pra licitar. Es un real, puede tener decimales

function verificarDirectorioProcesados {
	#Si el directorio de procesados no existe lo crea
	if [ ! -d "$PROCDIR" ]; then
		mkdir "$PROCDIR"
	fi

	#Si el directorio de ofertas validas no existe lo crea
	if [ ! -d "$PROCDIR/validas" ]; then
		mkdir "$PROCDIR/validas"
	fi

	#Si el directorio de procesadas no existe lo crea
	if [ ! -d "$PROCDIR/procesadas" ]; then
		mkdir "$PROCDIR/procesadas"
	fi

	#Si el directorio de rechazadas no existe lo crea
	if [ ! -d "$PROCDIR/rechazadas" ]; then
		mkdir "$PROCDIR/rechazadas"
	fi


}

function inicializarBitacora {
	cantFicheros=`ls "$OKDIR" | wc -l`
	if [ $cantFicheros != "0" ]; then
		$BINDIR/GrabarBitacora.sh "ProcesarOfertas" "Inicio de ProcesarOfertas - Cantidad de archivos a procesar: $cantFicheros"
	else
		$BINDIR/GrabarBitacora.sh "ProcesarOfertas" "Inicio de ProcesarOfertas - NO hay archivos para procesar."
	fi
}

function verificarCampos {
	echo "entre a veriicar campos joya"
	#cat $PROCDIR/procesadas/$1 | awk -F;
}

function verificarDuplicado {
	#Si el fichero ya fue procesado, lo muevo a NOKDIR
	if [ -f "$PROCDIR/procesadas/$1" ]; then
		$BINDIR/MoverArchivos.sh "$OKDIR/$1" "$NOKDIR"
		$BINDIR/GrabarBitacora.sh "ProcesarOfertas" "Se rechaza el archivo $1 por estar DUPLICADO."
		return "1"
	else
		#Muevo el archivo a PROCDIR/procesadas
		#$BINDIR/MoverArchivos.sh "$OKDIR/$1" "$PROCDIR/procesadas/$1"
		return "0"
	fi
}

function procesarArchivos {
	inicializarBitacora
	for file in `$BINDIR/indiceAceptados.pl`; do
		echo "hola"
		#verificarDuplicado $file
		#if [ $? = "0" ]; then
		#	verificarCampos $file
		#fi
	done
	
}

verificarDirectorioProcesados
procesarArchivos




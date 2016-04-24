#!/bin/bash

function verificarDirectorioProcesados {
	#Si el directorio de procesados no existe lo crea
	if [ ! -d "$PROCDIR" ]; then
		mkdir "$PROCDIR"
	fi

	#Si el directorio de procesadas no existe lo crea
	if [ ! -d "$PROCDIRP" ]; then
		mkdir -p "$PROCDIRP"
	fi

	#Si el directorio de ofertas validas no existe lo crea
	if [ ! -d "$PROCDIRV" ]; then
		mkdir -p "$PROCDIRV"
	fi

	#Si el directorio de rechazadas no existe lo crea
	if [ ! -d "$PROCDIRR" ]; then
		mkdir -p "$PROCDIRR"
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

function verificarDuplicado {
	#Si el fichero ya fue procesado, lo muevo a NOKDIR
	if [ -f "$PROCDIRP/$1" ]; then
		$BINDIR/MoverArchivos.sh "$OKDIR/$1" "$NOKDIR"
		$BINDIR/GrabarBitacora.sh "ProcesarOfertas" "Se rechaza el archivo $1 por estar DUPLICADO."
		return "1"
	else
		return "0"
	fi
}

function validarOferta {
	#Creo la lista de grupos
	listaGrupos=`cat $OKDIR/$1 | grep "^[^;]*;[^;]*$" | sed "s-\([0-9]\)\([0-9]\)\([0-9]\)\([0-9]\).*-\1\2\3\4-"`
	echo $listaGrupos

	#POR ACA QUEDEEEEEEEEEEEEEEEEEEEEEEEEEEE

}

function verificarEstructura {
	#El tp dice validar solo la primer linea, para hacerlo mas robusto, se valida todo el archivo. Si una linea no cumple, se da el archivo por erroneo

	if [ `grep "^[^;]*;[^;]*;.*$" "$OKDIR/$1" | wc -c` != "0" ]; then
		$BINDIR/MoverArchivos.sh "$OKDIR/$1" "$NOKDIR"
		$BINDIR/GrabarBitacora.sh "ProcesarOfertas" "Se rechaza el archivo $1 porque su estructura no se corresponde con el formato esperado."
	else
		$BINDIR/GrabarBitacora.sh "ProcesarOfertas" "Archivo a procesar: $1"
		validarOferta $1
	fi
}

function procesarArchivos {
	inicializarBitacora
	for file in `$BINDIR/indiceAceptados.pl`; do
		verificarDuplicado $file
		if [ $? = "0" ]; then
			verificarEstructura $file
		fi
	done
	
}

verificarDirectorioProcesados
procesarArchivos




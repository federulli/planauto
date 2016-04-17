#!/bin/bash
# primer parametro nombre de script a ejecutar
# segundo parametro F si se ejecuta en foreground o B si se ejecuta en background por defecto en foreground
# Para que funcione correctamente todos los procesos tienen q tener /bin/bash al inicio, si no no aparece el nombre del script ejecutando ps

script_padre="start" #El demonio necesita saber si va a ser iniciado o detenido, esta variable cumple esa funcion
export script_padre

if [ $# -lt 1 ]; then
	echo "Debe indicar el nombre del script a ejecutar"
	exit
fi

nombre=`echo $1 | sed "s/\([^\.]*\).*/\1.sh/"`

ground="F"
if [ $# -eq 2 ]; then
	if [ $2 != "B" ] && [ $2 != "F" ]; then
		echo "Modo desconocido"
		exit
	fi
	ground=$2
fi

if [ "$AMBIENTE_INICIALIZADO" != "SI" ]; then
	echo Ambiente no inicializado, no se puede ejecutar $1
	exit
fi

#verifico que el proceso no se encuentre en ejecucion


if ! [ -z `pidof -x $nombre` ]; then
	echo "El proceso ya se encuentra en ejecucion"
	exit
fi

if [ -f "$BINDIR/$nombre" ]; then
	if [ $ground == "B" ]; then
		$BINDIR/$nombre &
	else
		$BINDIR/$nombre
	fi
else
	echo "No se encuentra el ejecutable en $BINDIR"
fi
		
		

	
	


#!/bin/bash

function verificar_permisos_ejecucion {
	old_ifs=$IFS
	IFS=$'\n'
	files=`ls -l $BINDIR | grep "^[-wrx]\{9\}[^x]" | sed "s/^.* \([^\ ]*\)$/\1/"`
	
	for file in $files; do
		if ! [ -z "`chmod +x "$file" 2>&1`" ]; then
			echo No se pudo cambiar los permisos ejecucion del archivo: $file
			IFS=$old_ifs
			return 1
		 fi
	done
	IFS=$old_ifs
	return 0 
}

function copiar_de_directorio_de_resguardo {
	backupdir=`cat "../config/CIPAL.cnf" | grep "^BACKUPDIR" | sed "s/^BACKUPDIR=\([^=]*\)=[^=]*=[^=]*$/\1/"`

	if [ ! -f $backupdir/$1 ]; then
             echo "$1 no se encuentra en el directorio de resguardo $backupdir" 
             return 1
        fi
	cp -n $backupdir/$1 $2
	echo $1 restaurado
	return 0
}

function verificar_integridad_instalacion {
	old_ifs=$IFS
        IFS=','
        files=`cat "../config/CIPAL.cnf" | grep "^BINFILES" | sed "s/^BINFILES=\([^=]*\)=[^=]*=[^=]*/\1/"`
        for file in $files; do
                if ! [ -f "$BINDIR/$file" ]; then
                        echo No se encuentra el archivo: $file
			echo Se intentara copiar desde el directorio de resguardo 
			copiar_de_directorio_de_resguardo $file "$BINDIR"
                        if [ $? -eq 1 ]; then
				echo No se puede realizar la copia
				IFS=$old_ifs
	               		return 1
			fi
                fi
        done
	files=`cat "../config/CIPAL.cnf" | grep "^MAEFILES" | sed "s/^MAEFILES=\([^=]*\)=[^=]*=[^=]*/\1/"`
        for file in $files; do
                if ! [ -f "$MAEDIR/$file" ]; then
                        echo No se encuentra el archivo: $file
                        echo Se intentara copiar desde el directorio de resguardo 
                        copiar_de_directorio_de_resguardo $file "$MAEDIR"
                        if [ $? -eq 1 ]; then
                                echo No se puede realizar la copia
                                IFS=$old_ifs
                                return 1
                        fi
		 fi
        done
        IFS=$old_ifs
	return 0
}


function verificar_permisos_lectura {
	old_ifs=$IFS
        IFS=$'\n'
        # Permisos de lectura
	files=`ls -l $MAEDIR | grep "^[-rwx]\{7\}[\-]" | sed "s/^.* \([^\ ]*\)$/\1/"`
	for file in $files; do
                if ! [ -z "`chmod +r "$MAEDIR/$file" 2>&1`" ]; then
                        echo No se pudo cambiar los permisos de lectura del archivo: $file
                        IFS=$old_ifs
                        return 1
                 fi
        done
        IFS=$old_ifs
	return 0
}

function verificar_permisos_escritura {
	old_ifs=$IFS
        IFS=$'\n'
        # Permisos de escritura
        files=`ls -l $MAEDIR | grep "^[-rwx]\{5\}[\-]" | sed "s/^.* \([^\ ]*\)$/\1/"`
        for file in $files; do
                if ! [ -z "`chmod +w "$MAEDIR/$file" 2>&1`" ]; then
                        echo No se pudo cambiar los permisos de escritura del archivo: $file
                        IFS=$old_ifs
                        return 1
                 fi
        done
        IFS=$old_ifs
        return 0
}

function verificar_permisos_maestros {
	verificar_permisos_lectura
	if (( $? == 1 )); then 
		return 1
	fi
	verificar_permisos_escritura
	if (( $? == 1 )); then
                return 1
        fi
	return 0
}

function verificar_permisos {
	verificar_permisos_ejecucion
	if (( $? == 1 )); then
		return 1
	fi
	verificar_permisos_maestros
	if (( $? == 1 )); then
                return 1
        fi
	return 0
}

function inicializar_variables {
	BINDIR=`cat "../config/CIPAL.cnf" | grep "^BINDIR" | sed "s/^BINDIR=\([^=]*\)=[^=]*=[^=]*$/\1/"`
	export BINDIR
	MAEDIR=`cat "../config/CIPAL.cnf" | grep "^MAEDIR" | sed "s/^MAEDIR=\([^=]*\)=[^=]*=[^=]*$/\1/"`
	export MAEDIR
	ARRIDIR=`cat "../config/CIPAL.cnf" | grep "^ARRIDIR" | sed "s/^ARRIDIR=\([^=]*\)=[^=]*=[^=]*/\1/"`
	export ARRIDIR
	OKDIR=`cat "../config/CIPAL.cnf" | grep "^OKDIR" | sed "s/^OKDIR=\([^=]*\)=[^=]*=[^=]*/\1/"`
	export OKDIR
	PROCDIR=`cat "../config/CIPAL.cnf" | grep "^PROCDIR" | sed "s/^PROCDIR=\([^=]*\)=[^=]*=[^=]*/\1/"`
	export PROCDIR
	INFODIR=`cat "../config/CIPAL.cnf" | grep "^INFODIR" | sed "s/^INFODIR=\([^=]*\)=[^=]*=[^=]*/\1/"`
	export INFODIR
	LOGDIR=`cat "../config/CIPAL.cnf" | grep "^LOGDIR" | sed "s/^LOGDIR=\([^=]*\)=[^=]*=[^=]*/\1/"`
	export LOGDIR
	NOKDIR=`cat "../config/CIPAL.cnf" | grep "^NOKDIR" | sed "s/^NOKDIR=\([^=]*\)=[^=]*=[^=]*/\1/"`
	export NOKDIR
	LOGSIZE=`cat "../config/CIPAL.cnf" | grep "^LOGSIZE" | sed "s/^LOGSIZE=\([^=]*\)=[^=]*=[^=]*/\1/"`
	export LOGSIZE
	SLEEPTIME=`cat "../config/CIPAL.cnf" | grep "^SLEEPTIME" | sed "s/^SLEEPTIME=\([^=]*\)=[^=]*=[^=]*/\1/"`
	export SLEEPTIME
	return 0
}

function loguear_valor_variables {
	$BINDIR/GrabarBitacora.sh "PrepararAmbiente" "BINDIR=$BINDIR"
	$BINDIR/GrabarBitacora.sh "PrepararAmbiente" "MAEDIR=$MAEDIR"
	$BINDIR/GrabarBitacora.sh "PrepararAmbiente" "ARRIDIR=$ARRIDIR"
	$BINDIR/GrabarBitacora.sh "PrepararAmbiente" "OKDIR=$OKDIR"
	$BINDIR/GrabarBitacora.sh "PrepararAmbiente" "PROCDIR=$PROCDIR"
	$BINDIR/GrabarBitacora.sh "PrepararAmbiente" "INFODIR=$INFODIR"
	$BINDIR/GrabarBitacora.sh "PrepararAmbiente" "LOGDIR=$LOGDIR"
	$BINDIR/GrabarBitacora.sh "PrepararAmbiente" "NOKDIR=$NOKDIR"
	$BINDIR/GrabarBitacora.sh "PrepararAmbiente" "LOGSIZE=$LOGSIZE"
	$BINDIR/GrabarBitacora.sh "PrepararAmbiente" "SLEEPTIME=$SLEEPTIME"
	return 0
}

function arrancar_recibir_ofertas {
	echo "¿Desea efectuar la activación de RecibirOfertas? si – no"
	read arrancar
	while [ $arrancar != "si" ] && [ $arrancar != "no" ]; do
		echo "Opcion incorrecta"
		echo "¿Desea efectuar la activación de RecibirOfertas? si – no"
		read arrancar
	done
	if [ $arrancar == "si" ]; then
			$BINDIR/LanzarProceso.sh "RecibirOfertas.sh start" "B"
			mensaje="Recibir ofertas corriendo bajo el no.: `pgrep -f  RecibirOfertas.sh`"
			echo $mensaje
		else
			echo "Para ejecutar RecibirOfertas:"
			echo "\$ $BINDIR/LanzarProceso.sh RecibirOfertas B"
	fi
	return 0
}

if [ "$AMBIENTE_INICIALIZADO" == "SI" ]; then
	echo "Ambiente ya inicializado, para reiniciar termine la sesión e ingrese nuevamente"
	$BINDIR/GrabarBitacora.sh "PrepararAmbiente" "Ambiente ya inicializado" "ERR"
	return 1
fi

inicializar_variables

verificar_integridad_instalacion
instalacion_ok=$?

verificar_permisos
permisos_ok=$?

if [ $instalacion_ok -eq 0 ] && [ $permisos_ok -eq 0 ];
	then
		AMBIENTE_INICIALIZADO="SI"
		export AMBIENTE_INICIALIZADO
		loguear_valor_variables
		echo "Estado del Sistema: INICIALIZADO"
		$BINDIR/GrabarBitacora.sh "PrepararAmbiente" "Estado del Sistema: INICIALIZADO"
		arrancar_recibir_ofertas
	else 
		echo "No se puede inicializar el ambiente"
fi





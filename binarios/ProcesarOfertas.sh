#!/bin/bash

#Inicializo contadores
registrosLeidos=0
cantidadDeOfertasValidas=0
cantidadDeOfertasRechazadas=0

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

function rechazarRegistro { #Fuente #Motivo #ContratoFusionado
	cantidadDeOfertasRechazadas=$((cantidadDeOfertasRechazadas+1))

	codigo=`echo $1 | sed "s-\([^_]*\).*-\1-"`

	fuente=$1
	motivo=$2
	registro=`cat $OKDIR/$1 | grep "$3"`
	usuario=$USER
	fecha=`date`

	local file="$PROCDIRR/$codigo.rech"
	echo "$fuente;$motivo;$registro;$usuario;$fecha" >> $file
}

function obtenerFechaAdjudicacion {
	#Tomo la fecha del mes actual y comparo el dia para ver si es mayor a la fecha actual
	mesActual=`date +%m`
	fechaMesActual=`cat $MAEDIR/FechasAdj.csv | grep "[0-9][0-9]/$mesActual" | sed "s-\([^;]*\).*-\1-"`
	diaCorrespondienteAMesActual=`echo $fechaMesActual | sed "s-\([^\/]*\).*-\1-"`
	diaDeHoy=`date +%d`

	#$expr se usa porque -gt da error si la fecha es 01..09, necesito que elimine el 0 del principio para comparar
	diaValido=`echo $(expr $diaDeHoy - 0 )`

	if [[ $diaCorrespondienteAMesActual -gt $diaValido ]]; then
		fechaAdjudicacion=`cat $MAEDIR/FechasAdj.csv | grep "$diaCorrespondienteAMesActual/$mesActual" | sed "s-\([^;]*\).*-\1-"`
		#Fecha valida es en formato aaaammdd
		fechaValida=`echo $fechaAdjudicacion | sed "s-\([^\/]*\)\/\([^\/]*\)\/\([^\/]*\).*-\3\2\1-"`
	
	else
		#Si el dia actual supera al dia de adjudicacion del mes actual, simplemente tomo la fecha del mes siguiente
		mesProximoActo=`date +%m --date='+1 month'`
		fechaProximoActo=`cat $MAEDIR/FechasAdj.csv | grep "[0-9][0-9]/$mesProximoActo" | sed "s-\([^;]*\).*-\1-"`

		#Fecha valida es en formato aaaammdd
		fechaValida=`echo $fechaProximoActo | sed "s-\([^\/]*\)\/\([^\/]*\)\/\([^\/]*\).*-\3\2\1-"`
	fi
}

function validarSuscriptorUnico {
	nombresSuscriptores=`cat $MAEDIR/SuscriptoresProcesados.csv | grep $1`
	if [ -z "$nombresSuscriptores" ]; then
		return 0 #La cadena esta vacia, no hay problema por aqui
	else
		return 1 #El nombre de suscriptor ya fue procesado, hay que descartar la oferta
	fi
}

function verificarRegistro { # Fuente, contratoFusionado 
	codigo=`echo $1 | sed "s-\([^_]*\).*-\1-"`
	
	if [ ! -f "$MAEDIR/SuscriptoresProcesados.csv" ]; then
		> $MAEDIR/SuscriptoresProcesados.csv
	fi
	nombreSuscriptor=`cat $MAEDIR/temaL_padron.csv | grep "$grupo;$numeroDeOrden" | sed "s-[^;]*;[^;]*;\([^;]*\).*-\1-"`
	validarSuscriptorUnico $nombreSuscriptor

	if [ $? = "0" ]; then
		#Seteo la fecha valida del proximo acto de adjudicacion $fechaValida (formato aaaammdd)
		obtenerFechaAdjudicacion

		cantidadDeOfertasValidas=$((cantidadDeOfertasValidas+1))

		contratoFusionado=$2
		grupo=`echo $2 | sed "s-\([0-9]\)\([0-9]\)\([0-9]\)\([0-9]\).*-\1\2\3\4-"`
		numeroDeOrden=`echo $2 | sed "s-[0-9][0-9][0-9][0-9]\([0-9]\)\([0-9]\)\([0-9]\).*-\1\2\3-"`
		importeOfertado=`cat $OKDIR/$1 | grep $2 | sed "s-[^;]*;\(.*\)-\1-"`

		usuario=$USER
		fecha=`date`
	
		local file="$PROCDIRV/$fechaValida.txt"
		echo "$codigo;$fechaValida;$contratoFusionado;$grupo;$numeroDeOrden;$importeOfertado;$nombreSuscriptor;$usuario;$fecha" >> $file

		#Agrego el suscriptor al archivo de suscriptores unicos
		echo $nombreSuscriptor >> /$MAEDIR/SuscriptoresProcesados.csv
	else
		motivo="El suscriptor $nombreSuscriptor ya posee una oferta valida procesada"
		rechazarRegistro $1 "$motivo" $2
	fi
}

function inicializarBitacora {
	#Si no existe la carpeta de aceptados la creo
	#Puede que el usuario no haya ejecutado previamente RecibirOfertas, lo que generaria un error en este paso
	if [ ! -d "$OKDIR" ]; then
		mkdir "$OKDIR"
	fi

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

function validarParticipacion {
	participa=`cat $MAEDIR/temaL_padron.csv | grep "$1;$2" | sed "s-[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;\([^;]*\);.*-\1-"`
	
	if [[ $participa = "1" ]] || [[ $participa = "2" ]]; then
		verificarRegistro "$3" "$4"
	else
		rechazarRegistro "$3" "Suscriptor no puede participar" "$4"
	fi
}

function validarImporte {
	primeraCondicion=false #Monto minimo
	segundaCondicion=false #Monto maximo

	valorCuotaPura=`cat $MAEDIR/grupos.csv | grep "$1" | sed "s-[^;]*;[^;]*;[^;]*;\([^;]*\).*-\1-"`
	cantCuotasLicitar=`cat $MAEDIR/grupos.csv | grep "$1" | sed "s-[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;\([^;]*\).*-\1-"`
	cantCuotasPendientes=`cat $MAEDIR/grupos.csv | grep "$1" | sed "s-[^;]*;[^;]*;[^;]*;[^;]*;\([^;]*\).*-\1-"`
	
	#Lo que oferta el usuario
	importe=`cat $OKDIR/$3 | grep "$2" | sed "s-[^;]*;\(.*\)-\1-"`
	importeOfertado=`echo $importe | sed "s/,/./g"`
	cuotaPura=`echo $valorCuotaPura | sed "s/,/./g"`
	
	#Valores finales de interes
	montoMinimo=`echo "scale=2; $cuotaPura * $cantCuotasLicitar" | bc`
	montoMaximo=`echo "scale=2; $cuotaPura * $cantCuotasPendientes" | bc`

	#Validaciones con bc para poder trabajar con decimales
	validoMontoMinimo=$( echo "$importeOfertado>=$montoMinimo" | bc )

		if [ $validoMontoMinimo -eq 0 ]; then # 0 falso 1 verdadero
			primeraCondicion=false
		else
			primeraCondicion=true	
		fi
	validoMontoMaximo=$( echo "$importeOfertado<=$montoMaximo" | bc )
		if [ $validoMontoMaximo -eq 0 ]; then
			segundaCondicion=false
	
		else
			segundaCondicion=true
		fi

	if [[ $primeraCondicion = false ]]; then
		rechazarRegistro "$3" "No alcanza el monto minimo" "$2"
	elif [[ $segundaCondicion = false ]]; then
		rechazarRegistro "$3" "Supera el monto maximo" "$2"
	elif [[ $primeraCondicion = true ]] && [[ $segundaCondicion = true ]]; then
		validarParticipacion $1 $4 $3 $2 #Grupo, numero de orden, archivo, contratoFusionado
	fi 
}

function validarContratoFusionado {
	#Verifico que el contrato fusionado existe en el padron de suscriptores
	encontrado=false
	contratoFusionado=$1$2 #Grupo + Numero de orden
	for padron in $3; do
		if [ $contratoFusionado = $padron ]; then
			encontrado=true
			break
		fi
	done

	if [ $encontrado = true ]; then
		validarImporte $1 $contratoFusionado $4 $2 # $1=Grupo $4=Nombre de archivo
	else
		rechazarRegistro $4 "Contrato no encontrado" $contratoFusionado
	fi
}

function validarGrupo {
	padronDeSuscriptores=`cat $MAEDIR/temaL_padron.csv | sed "s-\([^;]*\);\([^;]*\);.*-\1\2-"`

	#Creo la lista de grupo y numero de orden
	lista=`cat $OKDIR/$1 | grep "^[^;]*;[^;]*$" | sed "s-\([^;]*\).*-\1-"`

	for contrato in $lista; do
		registrosLeidos=$((registrosLeidos+1))

		grupo=`echo $contrato | sed "s-\([0-9]\)\([0-9]\)\([0-9]\)\([0-9]\).*-\1\2\3\4-"`
		estadoDeGrupo=`cat $MAEDIR/grupos.csv | grep "$grupo" | sed "s-[^;]*;\([^;]*\);.*-\1-"`
		if [ $estadoDeGrupo = "CERRADO" ]; then
			rechazarRegistro $1 "Grupo CERRADO" $contrato
		else	
			numeroDeOrden=`echo $contrato | sed "s-[0-9][0-9][0-9][0-9]\([0-9]\)\([0-9]\)\([0-9]\)-\1\2\3-"`
			validarContratoFusionado "$grupo" "$numeroDeOrden" "$padronDeSuscriptores" "$1" #$1=file
		fi
	done
}

function verificarEstructura {
	#El tp dice validar solo la primer linea, para hacerlo mas robusto, se valida todo el archivo. Si una linea no cumple, se da el archivo por erroneo

	if [ `grep "^[^;]*;[^;]*;.*$" "$OKDIR/$1" | wc -c` != "0" ]; then
		$BINDIR/MoverArchivos.sh "$OKDIR/$1" "$NOKDIR"
		$BINDIR/GrabarBitacora.sh "ProcesarOfertas" "Se rechaza el archivo $1 porque su estructura no se corresponde con el formato esperado."
	else
		$BINDIR/GrabarBitacora.sh "ProcesarOfertas" "Archivo a procesar: $1"
		validarGrupo $1
	fi
}

function procesarArchivos {
	inicializarBitacora
	for file in `$BINDIR/indiceAceptados.pl`; do
		verificarDuplicado $file
		if [ $? = "0" ]; then
			verificarEstructura $file
			
			#Grabo los valores obtenidos para este archivo
			$BINDIR/GrabarBitacora.sh "ProcesarOfertas" "Registros Leidos: $registrosLeidos; Cantidad de ofertas validas: $cantidadDeOfertasValidas; Cantidad de ofertas rechazadas: $cantidadDeOfertasRechazadas"

			#Reinicio contadores para el proximo archivo
			registrosLeidos=0
			cantidadDeOfertasValidas=0
			cantidadDeOfertasRechazadas=0
		fi

	#Si el archivo no se movio a NOKDIR por algun error, lo muevo a PROCDIRP para que no sea procesado nuevamente
	if [ -f "$OKDIR/$file" ]; then
		$BINDIR/MoverArchivos.sh "$OKDIR/$file" "$PROCDIRP"
		$BINDIR/GrabarBitacora.sh "ProcesarOfertas" "Se mueve el archivo $file a /procesadas."
	fi

	done
}

$BINDIR/GrabarBitacora.sh "RecibirOfertas" "ProcesarOfertas corriendo bajo el nro.: `pgrep -f  ProcesarOfertas.sh`"
verificarDirectorioProcesados
procesarArchivos




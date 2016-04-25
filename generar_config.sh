if [ ! -d `pwd`/config ]; then
	mkdir `pwd`/config
fi
>`pwd`/config/CIPAL.cnf
echo GRUPO=`pwd`=$USER=`date`>>`pwd`/config/CIPAL.cnf
echo BINDIR=`pwd`/binarios=$USER=`date`>>`pwd`/config/CIPAL.cnf
echo MAEDIR=`pwd`/maestros=$USER=`date`>>`pwd`/config/CIPAL.cnf
echo ARRIDIR=`pwd`/arribados=$USER=`date`>>`pwd`/config/CIPAL.cnf
echo OKDIR=`pwd`/aceptados=$USER=`date`>>`pwd`/config/CIPAL.cnf
echo PROCDIR=`pwd`/procesados=$USER=`date`>>`pwd`/config/CIPAL.cnf
echo PROCDIRV=`pwd`/procesados/validas=$USER=`date`>>`pwd`/config/CIPAL.cnf
echo PROCDIRP=`pwd`/procesados/procesadas=$USER=`date`>>`pwd`/config/CIPAL.cnf
echo PROCDIRR=`pwd`/procesados/rechazadas=$USER=`date`>>`pwd`/config/CIPAL.cnf
echo INFODIR=`pwd`/informes=$USER=`date`>>`pwd`/config/CIPAL.cnf
echo LOGDIR=`pwd`/bitacoras=$USER=`date`>>`pwd`/config/CIPAL.cnf
echo NOKDIR=`pwd`/rechazados=$USER=`date`>>`pwd`/config/CIPAL.cnf
echo LOGSIZE=1000=$USER=`date`>>`pwd`/config/CIPAL.cnf
echo SLEEPTIME=10=$USER=`date`>>`pwd`/config/CIPAL.cnf
echo BINFILES=DetenerProceso.sh,GrabarBitacora.sh,LanzarProceso.sh,MoverArchivos.sh,PrepararAmbiente.sh,RecibirOfertas.sh,GenerarSorteo.sh,ProcesarOfertas.sh,DeterminarGanadores.pl=$USER=`date`>>`pwd`/config/CIPAL.cnf
echo MAEFILES=concesionarios.csv,FechasAdj.csv,grupos.csv,temaL_padron.csv=$USER=`date`>>`pwd`/config/CIPAL.cnf
echo BACKUPDIR=`pwd`/resguardo=$USER=`date`>>`pwd`/config/CIPAL.cnf

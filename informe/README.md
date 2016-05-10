# planauto
TP Sistemas Operativos. 
Grupo 04

Booteo:
1) Desde el bios setear para que bootee desde el pendrive
2) Seleccionar try without installing
3) Abrir una terminal
4) cd fiuba

Instalacion:
1) Descomprimir el archivo "instalador.tgz" donde desee.
2) Dentro de la carpeta GRUPO4 ejecutar setup.sh dar permisos de ejecucion si no los posee por medio de chmod +x setup.sh

Ejecucion:
1) Desde el directorio raiz del programa, ingresar a la carpeta de binarios (cd binarios)
2) Una vez en la carpeta /binarios, ejecutar PrepararAmbiente.sh de la siguiente forma . ./PrepararAmbiente.sh
3) Para ejecutar RecibirOfertas.sh de forma manual ingrese a la carpeta binarios ./LanzarProceso.sh RecibirOfertas B ( F si desea lanzarlo en foreground o B si desea lanzarlo en Background)
4) Para detener proceso ./DetenerProceso.sh RecibirOfertas


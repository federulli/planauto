#!/usr/bin/perl
#use strict;
#use warnings;


sub obtener_nombre_archivo_sorteo {
      #Devuelve el nombre del archivo de sorteo que contanga el id pasado por parametro
      $id = @_[0];
      opendir(PROCDIR, $ENV{'PROCDIR'});
      @files = readdir(PROCDIR);
      @files = grep /^$id/, @files;
      if ( scalar @files < 1) {
                return "";
      }
      return @files[0];
      close(PROCDIR);
}

#Devuelve los nro de grupos abiertos en el arreglo recibido
sub obtener_grupos {
	@grupos_por_parametro = grep /^\d{4}$/, @_;
	my @grupos_en_rango_por_parametro = &obtener_grupos_en_rango(@_);
	push(@grupos_por_parametro, @grupos_en_rango_por_parametro);
	my %hash_aux = map{$_,1} @grupos_por_parametro;
	@grupos_por_parametro = keys %hash;
	if (scalar @grupos_por_parametro > 0){
		if (opendir(arch_grupos, "<$ENV{'MAEDIR'}/Grupos.csv")){
			@grupos_en_arch = readdir(arch_grupos);
			close(arch_grupos);
		}
		@grupos_activos = grep /^\d{4};ABIERTO/, @grupos_en_arch;
		foreach $grupo (@grupos_por_parametro){
			@grupo_activo = grep /^$grupo/, @grupos_en_arch;
			if (scalar @grupo_activo){
				push(@grupos, $grupo);
			}
		}
	}
	return @grupos;
}

#Devuelve todos los grupos dentro de los rangos que tiene el arreglo recibido
sub obtener_grupos_en_rango {
	@rango_grupos_por_parametro = grep /^\d{4}-\d{4}$/, @_;
	foreach $rango (@rango_grupos_por_parametro){
		$inicio = substr($rango, 0, 4);
		$fin = substr($rango, 5, 4);
		for ($i = $inicio; $i <= $fin; $i++){
			push($grupos, $i);
		}
	}
	return $grupos;
}

sub presentar_menu {
	print "menu\n";
}

sub resultado_general_sorteo {
	$id = @_[0];
	my $file = &obtener_nombre_archivo_sorteo($id);
	open (ENTRADA,"<$ENV{'PROCDIR'}/$file");
	my %orden_sorteo_h;
	while ($linea=<ENTRADA>) {	
		$linea =~ s/\D*(\d*)\D*(\d*)/\2 \1/;
		@orden_sorteo = split(" ", $linea);
		$orden_sorteo_h{@orden_sorteo[0]} = @orden_sorteo[1]
	}
	@keys = keys %orden_sorteo_h;
	@sorted_keys = sort(@keys);
	foreach $a (@sorted_keys) {
		if ( $a ne "" ) {
			print "Nro. de Sorteo $a, le correspondió al número de orden $orden_sorteo_h{$a}\n";
		}
	}
	close(ENTRADA);
	return 0;
}


# Verifico q el ambiente este inicializado
if ($ENV{'AMBIENTE_INICIALIZADO'} ne "SI" ) {
	print "Ambiente no inicializado.\n";
	exit;
}

if ( scalar @ARGV == 0 ) {
	print "Faltan parametros\n";
	exit;
}
# Verifico que no se este ejecutando
$processes = `ps -x -l`;
@procesos = split("\n",$processes);
@procesos = grep /$0/, @procesos;
foreach $proc (@procesos) {
	if ( ! $proc =~ /$$/ ) {
		print "$0 ya se encuentra en ejecucion.\n";
		exit;
	}
}

# Veririfico si tengo q imprimir mensaje de ayuda
@ayuda = grep /^-a$/, @ARGV;
if (scalar @ayuda > 0) {
	print "mensaje ayuda\n";
	exit;
}


# Verifico que exista el archivo 
$id = shift(@ARGV);
$archivo = &obtener_nombre_archivo_sorteo($id);
if ( $archivo eq "") {
	print "No se encuentra el archvio de sorteo con id: $id\n";
	exit;
}
# Verifico si tengo q guardar en archivo
@guardar_en_archivo = grep /^-g$/, @ARGV;
$g = 0;
if (scalar @guardar_en_archivo) {
	$g = 1;
}

@grupos = &obtener_grupos(@ARGV);

%opciones = ("resultado_general", 1, "ganadores_sorteo", 2, "ganadores_licitacion", 3, "resultado_por_grupo", 4);
&presentar_menu;
while ( $opcion = <STDIN> ) {
	chop($opcion);
	if ($opcion == $opciones{resultado_general}) {&resultado_general_sorteo($id);}
	#else if ($opcion == $opciones{ganadores_sorteo}) {&ganadores_por_sorteo($id, @grupos);}
	#else if ($opcion == $opciones{ganadores_licitacion}) {&ganadores_por_licitacion($id, @grupos);}
	#else if ($opcion == $opciones{resultado_por_grupo}) {&resultado_por_grupo($id, @grupos);
	&presentar_menu;
}

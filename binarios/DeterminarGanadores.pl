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
$id = @ARGV[0];
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

$opcion="1";
while ( $opcion != "0" ) {
	$opcion = <STDIN>;
	if ($opcion == "1") {&resultado_general_sorteo($id);}
	
}

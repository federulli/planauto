#!/usr/bin/perl
#use strict;
#use warnings;


sub resultado_general_sorteo {
	@id = @_[0];
	opendir(PROCDIR, $ENV{'PROCDIR'});
	@files = readdir(PROCDIR); 
	@files = grep /^@id[0]/, @files;
	if ( scalar @files < 1) {
		print "No hay sorteo con id @id[0]";
		return 1;
	}
	#open (ENTRADA,"<"@files[0]")
	return 0;
}

if ($ENV{'AMBIENTE_INICIALIZADO'} ne "SI" ) {
	print "Ambiente no inicializado.\n";
	exit;
}

$processes = `ps -x -l`;


@procesos = split("\n",$processes);
@procesos = grep /$0/, @procesos;

foreach $proc (@procesos) {
	if ( ! $proc =~ /$$/ ) {
		print "$0 ya se encuentra en ejecucion.\n";
		exit;
	}
}


@ayuda = grep /^-a$/, @ARGV;

if (scalar @ayuda > 0) {
	print "mensaje ayuda\n";
	exit;
}

@guardar_en_archivo = grep /^-g$/, @ARGV;
if (scalar @guardar_en_archivo) {
	$g = 1;
}

$id = @ARGV[0];
$opcion="1";
while ( $opcion != "0" ) {
	$opcion = <STDIN>;
	if ($opcion == "1") {&resultado_general_sorteo($id);}
	
}

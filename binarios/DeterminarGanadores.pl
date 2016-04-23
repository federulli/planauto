#!/usr/bin/perl
#use strict;
#use warnings;


sub obtener_nombre_archivo_sorteo {
      #Devuelve el nombre del archivo de sorteo que contanga el id pasado por parametro
      $id = @_[0];
      opendir(sorteos, "$ENV{'PROCDIR'})/sorteos";
      @files = readdir(sorteos);
      @files = grep /^$id/, @files;
      if ( scalar @files < 1) {
                return "";
      }
      close(sorteos);
      return @files[0];
}


#Devuelve los nro de grupos abiertos en el arreglo recibido
sub obtener_grupos {
	#SI se piden todos los grupos abiertos
	my @todos = grep /^*$/, @_;
	my @grupos;
	if (scalar @todos){
		if (opendir(GRUPOS, "<$ENV{'MAEDIR'}/Grupos.csv")){
			@grupos_en_arch = readdir(GRUPOS);
			close(GRUPOS);
		}
		@grupos_activos = grep /^\d{4};ABIERTO/, @grupos_en_arch;
		foreach $grupo (@grupos_activos){
			@grupos = substr($grupo, 0, 4);
		}
	}

	#SI se piden algunos grupos
	else{
		my @grupos_por_parametro = grep /^\d{4}$/, @_;
		my @grupos_en_rango_por_parametro = &obtener_grupos_en_rango(@_);
		push(@grupos_por_parametro, @grupos_en_rango_por_parametro);
	
		#Elimino repeticiones
		my %hash_aux = map{$_,1} @grupos_por_parametro;
		@grupos_por_parametro = keys %hash;

		#Saco los grupos que no esten abiertos
		if (scalar @grupos_por_parametro > 0){
			if (opendir(GRUPOS, "<$ENV{'MAEDIR'}/Grupos.csv")){
				@grupos_en_arch = readdir(GRUPOS);
				close(GRUPOS);
			}
			@grupos_activos = grep /^\d{4};ABIERTO/, @grupos_en_arch;
			foreach $grupo (@grupos_por_parametro){
				@grupo_activo = grep /^$grupo/, @grupos_en_arch;
				if (scalar @grupo_activo){
					push(@grupos, $grupo);
				}
			}
		}
	}
	return @grupos;
}

#Devuelve todos los grupos dentro de los rangos que tiene el arreglo recibido
sub obtener_grupos_en_rango {
	my @rango_grupos_por_parametro = grep /^\d{4}-\d{4}$/, @_;
	my @grupos;
	foreach $rango (@rango_grupos_por_parametro){
		my ($inicio, $fin) = split("-", $rango);
		for ($i = $inicio; $i <= $fin; $i++){
			push(@grupos, $i);
		}
	}
	return @grupos;
}


sub presentar_menu {
	print "menu\n";
}


sub resultado_general_sorteo {
	my ($grabar, $id) = @_;
	my $file = &obtener_nombre_archivo_sorteo($id);
	open (ENTRADA,"<$ENV{'PROCDIR'}/sorteos/$file");
	my %orden_sorteo_h;
	while ($linea=<ENTRADA>) {
		$linea =~ s/\D*(\d*)\D*(\d*)/\2 \1/;
		@orden_sorteo = split(" ", $linea);
		$orden_sorteo_h{$orden_sorteo[1]} = $orden_sorteo[0]
	}
	@keys = keys %orden_sorteo_h;
	@sorted_keys = sort(@keys);
	foreach $a (@sorted_keys) {
		if ( $a ne "" ) {
			push(@resultado,"Nro. de Sorteo $a, le correspondió al número de orden $orden_sorteo_h{$a}\n");
			print $resultado[$#resultado];
		}
	}
	close(ENTRADA);
	return 0;
}


sub ganadores_por_sorteo {
	my ($id, @grupos) = @_;
	my $file = &obtener_nombre_archivo_sorteo($id);

	#Armo el titulo
	my $fecha_adj = $file;
	$fecha_adj =~ s/$id-//;
	$fecha_adj =~ s/.csv//;
	$titulo = "Ganadores del Sorteo ".$id." de fecha ".$fecha_adj."\n";
	print $titulo;

	#Averiguo orden sorteo
	open (ENTRADA,"<$ENV{'PROCDIR'}/sorteos/$file");
	my %orden_sorteo_h;
	while ($linea=<ENTRADA>) {	
		$linea =~ s/\D*(\d*)\D*(\d*)/\2 \1/;
		@orden_sorteo = split(" ", $linea);
		$orden_sorteo_h{@orden_sorteo[1]} = @orden_sorteo[0]
	}
	@orden_keys = keys %orden_sorteo_h;
	@orden_keys = sort(@keys);
	close(ENTRADA);

	#Averiguo ganador sorteo
	open (SUSCRIPTORES,"<$ENV{'MAEDIR'}/temaL_padron.csv");
	my %suscriptores_por_grupo;
	while ($suscriptor = <SUSCRIPTORES>){
		@info_suscriptor = split(";", $suscriptor);
		$matches = grep /$info_suscriptor[0]/, @grupos;
		if($matches ne ""){
			$suscriptores_por_grupo{$info_suscriptor[0]}{$info_suscriptor[1]} = $info_suscriptor[2];
	}
	%ganadores_sorteo_por_grupo;
	foreach $grupo (@grupos){
		for(i = 0; not exists($suscriptores_por_grupo{$grupo}{$orden_sorteo{@orden_keys[i]}}) ; i++);
		$ganadores_sorteo_por_grupo{$grupo} = [$orden_sorteo{@orden_keys[i]}, $suscriptores_por_grupo{$grupo}{$orden_sorteo{@orden_keys[i]}}, $orden_keys[i]]
	}
	return %ganadores_sorteo_por_grupo;
}

#Administra la obtención de los datos necesarios y la presentación de la opción ganadores por sorteo
sub resultado_ganadores_por_sorteo{
	($grabar, $id, @grupos) = @_;
	my %ganadores_por_grupo = &ganadores_por_sorteo($id, @grupos);
	@resultado;
	foreach $grupo (@keys(%ganadores_por_grupo){
		push(@resultado, "Ganador por sorteo del grupo ".$grupo.": Nro de Orden: ".$ganadores_por_grupo{$grupo}[0].", ".$ganadores_por_grupo{$grupo}[1]."(Nro. de Sorteo ".$ganadores_por_grupo{$grupo}[2].")\n");
	}
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
	if ($opcion == $opciones{resultado_general}) {&resultado_general_sorteo($g, $id);}
	else if ($opcion == $opciones{ganadores_sorteo}) {&resultado_ganadores_por_sorteo($g, $id, @grupos);}
	#else if ($opcion == $opciones{ganadores_licitacion}) {&ganadores_por_licitacion($id, $g, @grupos);}
	#else if ($opcion == $opciones{resultado_por_grupo}) {&resultado_por_grupo($id, $g, @grupos);
	&presentar_menu;
}

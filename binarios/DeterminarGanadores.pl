#!/usr/bin/perl
#use strict;
#use warnings;


sub obtener_nombre_archivo_sorteo {
      #Devuelve el nombre del archivo de sorteo que contanga el id pasado por parametro
      $id = @_[0];
      opendir(sorteos, "$ENV{'PROCDIR'})/sorteos");
      @files = readdir(sorteos);
      @files = grep /^$id/, @files;
      if ( scalar @files < 1) {
                return "";
      }
      close(sorteos);
      return @files[0];
}

#Recibe el nombre de un archivo de sorteo y su id, y devuelve la fecha de adjudicacion de dicho sorteo
sub obtener_fecha_de_adjudicacion {
	my ($fecha_adj, $id) = @_;
	$fecha_adj =~ s/$id-//;
	$fecha_adj =~ s/.csv//;
	return $fecha_adj;
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
			my @grupos_activos;
			open(GRUPOS, "<$ENV{'MAEDIR'}/Grupos.csv");
			while (my $grupo_existente = <GRUPOS>){
				$grupo_activo = grep /^\d{4};ABIERTO/, $grupo_existente;
				if ($grupo_activo ne ""){
					push(@grupos_activos, $grupo_activo);
				}
			}
			foreach $grupo (@grupos_por_parametro){
				@grupo_activo = grep /^$grupo/, @grupos_activos;
				if (scalar @grupo_activo){
					push(@grupos, $grupo);
				}
			}
			close(GRUPOS);
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

sub resultado_sorteo {
	my $file = @_;
	open (ENTRADA,"<$ENV{'PROCDIR'}/sorteos/$file");
	my %orden_sorteo_h;
	while ($linea=<ENTRADA>) {
		$linea =~ s/\D*(\d*)\D*(\d*)/\2 \1/;
		@orden_sorteo = split(" ", $linea);
		$orden_sorteo_h{$orden_sorteo[0]} = $orden_sorteo[1];
	}
	close(ENTRADA);
	return %orden_sorteo_h;
}


sub ganadores_por_sorteo {
	my ($id, @grupos) = @_;
	my $file = &obtener_nombre_archivo_sorteo($id);

	#Averiguo orden sorteo
	my %orden_sorteo_h = &resultado_sorteo($file);
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
	}
	close(SUSCRIPTORES);
	%ganadores_sorteo_por_grupo;
	foreach $grupo (@grupos){
		for($i = 0; not exists($suscriptores_por_grupo{$grupo}{$orden_sorteo{@orden_keys[$i]}}) ; $i++){}
		$ganadores_sorteo_por_grupo{$grupo} = [$orden_sorteo{@orden_keys[$i]}, $suscriptores_por_grupo{$grupo}{$orden_sorteo{@orden_keys[$i]}}, $orden_keys[$i]];
	}
	return %ganadores_sorteo_por_grupo;
}

sub ganadores_por_licitacion{
	my ($id, @grupos) = @_;
	$file_sorteo = &obtener_nombre_archivo_sorteo($id);
	$fecha_adj = &obtener_fecha_de_adjudicacion($file, $id);
	$file_licitacion = $fecha_adj.".txt";
	my %ganadores_por_sorteo = &ganadores_por_sorteo($id, @grupos);
	my %campos_ganadores_sorteo = ("orden", 0, "nombre", 1, "sorteo", 2);
	my %resultado_sorteo = &resultado_sorteo($file_sorteo);

	my %ganador_licitacion;
	open(LICITACIONES, "<$ENV{'PROCDIR'}/validas/.$file_licitacion");
	my %campos_licitacion = ("grupo", 3, "orden", 4, "importe", 5, "nombre", 6, "nro_sorteo", 7);
	while ($licitacion_existente = <LICITACIONES>){
		@licitacion = split(";", $licitacion_grupo_buscado);
		for ($i = 0; $i < $#grupos && $licitacion{grupo} ne $grupos[$i]; $i++){}
		if (i < $#grupos && $licitacion[$campos_licitacion{orden}] ne $ganadores_por_sorteo{$grupos[$i]}[$campos_ganadores_sorteo{orden}]){
			foreach $key (keys(%resultado_sorteo)){
				if ($resultado_sorteo[$key] eq $licitacion[$campos_licitacion{orden}]){
					$licitacion[$campos_licitacion{nro_sorteo}] = $key;
					last;
				}
			}

			if (not exists($ganador_licitacion{$licitacion[$campos_licitacion{grupo}]}) || $licitacion[$campos_licitacion{importe}] > $ganador_licitacion{$licitacion[$campos_licitacion{grupo}]}[1] || ($licitacion[$campos_licitacion{importe}] == $ganador_licitacion{$licitacion[$campos_licitacion{grupo}]}[1] && $licitacion[$campos_licitacion{nro_sorteo}] > $ganador_licitacion{$licitacion[$campos_licitacion{grupo}]}[3])){

				$ganador_licitacion{$licitacion[$campos_licitacion{grupo}]} = ($licitacion[$campos_licitacion{orden}], $licitacion[$campos_licitacion{importe}], $licitacion[$campos_licitacion{nombre}], $licitacion[$campos_licitacion{nro_sorteo}]);

			}
		}
	}
	close(LICITACIONES);
	return %ganador_licitacion;
}


sub resultado_general_sorteo {
	my ($grabar, $id) = @_;
	my $file = &obtener_nombre_archivo_sorteo($id);
	my %orden_sorteo_h = &resultado_sorteo($file);
	@keys = keys %orden_sorteo_h;
	@sorted_keys = sort(@keys);
	
	if ($grabar) {
		$file =~ s/csv/txt/;
		open(SALIDA, ">$ENV{'INFODIR'}/$file");
	}
	foreach $a (@sorted_keys) {
		if ( $a ne "" ) {
			$resultado = "Nro. de Sorteo $a, le correspondió al número de orden $orden_sorteo_h{$a}\n";
			print $resultado;
			if ($grabar) {print SALIDA $resultado;}
		}
	}
	if ($grabar) {close(SALIDA);}
	return 0;
}

#Administra la obtención de los datos necesarios y la presentación de la opción ganadores por sorteo
sub resultado_ganadores_por_sorteo{
	($grabar, $id, @grupos) = @_;
	my %ganadores_por_grupo = &ganadores_por_sorteo($id, @grupos);

	#Armo el titulo
	my $fecha_adj = &obtener_fecha_de_adjudicacion($file, $id);
	$titulo = "Ganadores del Sorteo ".$id." de fecha ".$fecha_adj."\n";
	print $titulo;

	if ($grabar) {
		my @grupos_ordenados = sort(@grupos);
		$arch_salida = $id."_S_Grd".$grupos_ordenados[0]."_Grh".$grupos_ordenados[$#grupos_ordenados]."_".$fecha_adj;
		open(SALIDA, ">$ENV{'INFODIR'}/$arch_salida");
	}
	@resultado;
	foreach $grupo (keys(%ganadores_por_grupo)){
		$resultado = "Ganador por sorteo del grupo ".$grupo.": Nro de Orden: ".$ganadores_por_grupo{$grupo}[0].", ".$ganadores_por_grupo{$grupo}[1]."(Nro. de Sorteo ".$ganadores_por_grupo{$grupo}[2].")\n";
		print $resultado;
		if ($grabar) {
			print SALIDA $resultado;
		}
	}
	if ($grabar) {
		close(SALIDA);
	}
	return 0;
}

#Administra la obtención de los datos necesarios y la presentación de la opción ganadores por sorteo
sub resultado_ganadores_por_licitacion{
	($grabar, $id, @grupos) = @_;
	my %ganadores_por_grupo = &ganadores_por_licitacion($id, @grupos);

	#Armo el titulo
	my $fecha_adj = &obtener_fecha_de_adjudicacion($file, $id);
	$titulo = "Ganadores por Licitación ".$id." de fecha ".$fecha_adj."\n";
	print $titulo;

	if ($grabar) {
		my @grupos_ordenados = sort(@grupos);
		$arch_salida = $id."_L_Grd".$grupos_ordenados[0]."_Grh".$grupos_ordenados[$#grupos_ordenados]."_".$fecha_adj;
		open(SALIDA, ">$ENV{'INFODIR'}/$arch_salida");
	}
	@resultado;
	foreach $grupo (keys(%ganadores_por_grupo)){
		$resultado = "Ganador por licitación del grupo $grupo: Nro de Orden: $ganadores_por_grupo{$grupo}[0], $ganadores_por_grupo{$grupo}[1] con \$$ganadores_por_grupo{$grupo}[2](Nro. de Sorteo $ganadores_por_grupo{$grupo}[3])\n";
		print $resultado;
		if ($grabar){
			print SALIDA $resultado;
		}
	}
	if ($grabar){
		close(SALIDA);
	}
	return 0;
}

sub resultado_por_grupos{
	($grabar, $id, @grupos) = @_;
	my %ganadores_por_sorteo = &ganadores_por_sorteo($id, @grupos);
	my %ganadores_por_licitacion = &ganadores_por_licitacion($id, @grupos);

	#Armo el titulo
	my $fecha_adj = &obtener_fecha_de_adjudicacion($file, $id);
	$titulo = "Ganadores por Grupo en el acto de adjudicación de fecha ".$fecha_adj.", Sorteo: ".$id."\n";
	print $titulo;

	@resultado;
	foreach $grupo (keys(%ganadores_por_sorteo)){
		if ($grabar) {
			$arch_salida = $id."_Grupo".$grupo."_".$fecha_adj;
			open(SALIDA, ">$ENV{'INFODIR'}/$arch_salida");
		}
		$resultado_sorteo = $grupo."-".$ganadores_por_sorteo{$grupo}[0]." S (".$ganadores_por_sorteo{$grupo}[1].")\n";
		$resultado_licitacion = $grupo."-".$ganadores_por_licitacion{$grupo}[0]." L (".$ganadores_por_licitacion{$grupo}[1].")\n";
		print $resultado_sorteo;
		print $resulotado_licitacion;
		if ($grabar) {
			print SALIDA $resultado_sorteo;
			print SALIDA $resulotado_licitacion;
			close(SALIDA);
		}
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
	if ($opcion eq $opciones{resultado_general}) {&resultado_general_sorteo($g, $id);}
	elsif ($opcion eq $opciones{ganadores_sorteo}) {&resultado_ganadores_por_sorteo($g, $id, @grupos);}
	elsif ($opcion eq $opciones{ganadores_licitacion}) {&resultado_ganadores_por_licitacion($g, $id, @grupos);}
	elsif ($opcion eq $opciones{resultado_por_grupo}) {&resultado_por_grupo($id, $g, @grupos);}
	&presentar_menu;
}

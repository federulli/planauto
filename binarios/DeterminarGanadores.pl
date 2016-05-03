#!/usr/bin/perl
#use strict;
#use warnings;


sub obtener_nombre_archivo_sorteo {
      #Devuelve el nombre del archivo de sorteo que contanga el id pasado por parametro
      $id = @_[0];
      opendir(SORTEOS, "$ENV{'PROCDIR'}/sorteos");
      @files = readdir(SORTEOS);
      @files = grep /^$id/, @files;
      if ( scalar @files < 1) {
                return "";
      }
      close(SORTEOS);
      return $files[0];
}

#Recibe el nombre de un archivo de sorteo y su id, y devuelve la fecha de adjudicacion de dicho sorteo
sub obtener_fecha_de_adjudicacion {
	my ($id) = @_;
	my $fecha_adj = obtener_nombre_archivo_sorteo($id);
	$fecha_adj =~ s/$id//;
	$fecha_adj =~ s/_//;
	$fecha_adj =~ s/.srt//;
	return $fecha_adj;
}

sub obtener_nombre_archivo_licitacion{
      #Devuelve el nombre del archivo de licitacion que contanga la fecha de adjudicacion pasada por parametro
      $fecha_adj = @_[0];
      opendir(VALIDAS, "$ENV{'PROCDIR'}/validas");
      @files = readdir(VALIDAS);
      @files = grep /^$fecha_adj/, @files;
      if ( scalar @files < 1) {
                return "";
      }
      close(VALIDAS);
      return $files[0];
}

sub sacar_duplicados {
    my %vistos;
    grep !$vistos{$_}++, @_;
}

#Devuelve los nro de grupos abiertos en el arreglo recibido
sub obtener_grupos {
	#SI se piden todos los grupos abiertos
	my @todos = grep /^\*grupos$/, @_;
	my @grupos;
	if (scalar @todos){
		open(GRUPOS, "<$ENV{'MAEDIR'}/grupos.csv");
		while (my $grupo_en_arch = <GRUPOS>) {
			@grupo_activo = grep /^\d{4};ABIERTO/, $grupo_en_arch;
			if ($grupo_activo[0] ne ""){
				@grupo_activo = split(";", $grupo_activo[0]);
				push(@grupos, $grupo_activo[0]);
			}
		}
		close(GRUPOS);
	}

	#SI se piden algunos grupos
	else{
		my @grupos_por_parametro = grep /^\d{4}$/, @_;
		my @grupos_en_rango_por_parametro = &obtener_grupos_en_rango(@_);
		push(@grupos_por_parametro, @grupos_en_rango_por_parametro);

		#Elimino repeticiones
		@grupos_por_parametro = sacar_duplicados(@grupos_por_parametro);

		#Saco los grupos que no esten abiertos
		if (scalar @grupos_por_parametro > 0){
			my @grupos_activos;
			open(GRUPOS, "<$ENV{'MAEDIR'}/grupos.csv");
			while (my $grupo_existente = <GRUPOS>){
				@grupo_activo = grep /^\d{4};ABIERTO/, $grupo_existente;
				if ($grupo_activo[0] ne ""){
					push(@grupos_activos, $grupo_activo[0]);
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
		for ($i = $inicio, $j = 0 + $inicio; $j <= $fin; $j++){
			if ($j != $inicio){
				$k = $j - 1;
				$i =~ s/$k$/$j/;
			}
			push(@grupos, $i);
		}
	}
	return @grupos;
}

sub presentar_menu {
	print "\nIngrese opción:
	1 - Resultado general del sorteo
	2 - Ganadores por sorteo
	3 - Ganadores por licitación
	4 - Resultados por grupo
	0 - Salir\n\n";
}

sub resultado_sorteo {
	my ($file) = @_;
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
	@keys = keys(%orden_sorteo_h);
	@orden_keys = sort {$a <=> $b} (@keys);
	close(ENTRADA);

	#Averiguo ganador sorteo
	open (SUSCRIPTORES,"<$ENV{'MAEDIR'}/temaL_padron.csv");
	my %suscriptores_por_grupo;
	my $participa = 5;
	while ($suscriptor = <SUSCRIPTORES>){
		@info_suscriptor = split(";", $suscriptor);
		if (($info_suscriptor[$participa] == 1 || $info_suscriptor[$participa] == 2)){
			@matches = grep /$info_suscriptor[0]/, @grupos;
			if(@matches != 0){
				$suscriptores_por_grupo{$info_suscriptor[0]}{$info_suscriptor[1]} = $info_suscriptor[2];
			}
		}
	}
	close(SUSCRIPTORES);

	%ganadores_sorteo_por_grupo;
	foreach $grupo (@grupos){
		for($i = 0; $i <= $#orden_keys && not exists($suscriptores_por_grupo{$grupo}{$orden_sorteo_h{$orden_keys[$i]}}); $i++){}
		if ($i <= $#orden_keys) {
			$ganadores_sorteo_por_grupo{$grupo} = [$orden_sorteo_h{@orden_keys[$i]}, $suscriptores_por_grupo{$grupo}{$orden_sorteo_h{@orden_keys[$i]}}, $orden_keys[$i]];
		}
	}
	return %ganadores_sorteo_por_grupo;
}

sub ganadores_por_licitacion{
	my ($id, @grupos) = @_;
	$file_sorteo = &obtener_nombre_archivo_sorteo($id);
	$fecha_adj = &obtener_fecha_de_adjudicacion($id);
	$file_licitacion = &obtener_nombre_archivo_licitacion($fecha_adj);
	if ($file_licitacion eq "") { return %inexistente; }
	my %ganadores_por_sorteo = &ganadores_por_sorteo($id, @grupos);
	my %campos_ganadores_sorteo = ("orden", 0, "nombre", 1, "sorteo", 2);
	my %resultado_sorteo = &resultado_sorteo($file_sorteo);

	#Armo arreglo con participantes
	@participantes;
	open(SUSCRIPTOS, "<$ENV{'MAEDIR'}/temaL_padron.csv");
	$participa = 5;
	while ($suscripto = <SUSCRIPTOS>){
		@suscripto = split(";", $suscripto);
		if ($suscripto[$participa] == 1 || $suscripto[$participa] == 2){
			push(@participantes, [$suscripto[0], $suscripto[1]]);
		}
	}
	close(SUSCRIPTOS);

	my %ganador_licitacion;
	open(LICITACIONES, "<$ENV{'PROCDIR'}/validas/$file_licitacion");
	my %campos_licitacion = ("grupo", 3, "orden", 4, "importe", 5, "nombre", 6, "nro_sorteo", 7);
	while ($licitacion_existente = <LICITACIONES>){
		@licitacion = split(";", $licitacion_existente);
		for ($i = 0; $i <= $#grupos && $licitacion[$campos_licitacion{grupo}] ne $grupos[$i]; $i++){}
		if ($i <= $#grupos && $licitacion[$campos_licitacion{orden}] ne $ganadores_por_sorteo{$grupos[$i]}[$campos_ganadores_sorteo{orden}]){
			for ($i = 0; $i < $#participantes && $licitacion{grupo} ne $participante[$i][0] && $licitacion{orden} ne $participante[$i][1]; $i++){}
			if ($i < $#participantes){
				foreach $key (keys(%resultado_sorteo)){
					if ($resultado_sorteo{$key} eq $licitacion[$campos_licitacion{orden}]){
						$licitacion[$campos_licitacion{nro_sorteo}] = $key;
						last;
					}
				}
				if ((not exists($ganador_licitacion{$licitacion[$campos_licitacion{grupo}]})) || $licitacion[$campos_licitacion{importe}] > $ganador_licitacion{$licitacion[$campos_licitacion{grupo}]}[1] || ($licitacion[$campos_licitacion{importe}] == $ganador_licitacion{$licitacion[$campos_licitacion{grupo}]}[1] && $licitacion[$campos_licitacion{nro_sorteo}] > $ganador_licitacion{$licitacion[$campos_licitacion{grupo}]}[3])){

					$ganador_licitacion{$licitacion[$campos_licitacion{grupo}]} = [$licitacion[$campos_licitacion{orden}], $licitacion[$campos_licitacion{importe}], $licitacion[$campos_licitacion{nombre}], $licitacion[$campos_licitacion{nro_sorteo}]];

				}
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
	@sorted_keys = sort {$a <=> $b} (@keys);
	
	if ($grabar) {
		$file =~ s/srt/txt/;
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
	my $fecha_adj = &obtener_fecha_de_adjudicacion($id);
	my $fecha_salida = $fecha_adj;
	$fecha_salida =~ s/(\d{4})(\d{2})(\d{2})/\3-\2-\1/;
	$titulo = "Ganadores del Sorteo ".$id." de fecha ".$fecha_salida."\n\n";
	print $titulo;

	if ($grabar) {
		my @grupos_ordenados = sort(@grupos);
		$arch_salida = $id."_S_Grd".$grupos_ordenados[0]."_Grh".$grupos_ordenados[$#grupos_ordenados]."_".$fecha_adj;
		open(SALIDA, ">$ENV{'INFODIR'}/$arch_salida");
		print SALIDA $titulo;
	}

	@grupos_consultados_ordenados = sort(keys(%ganadores_por_grupo));
	foreach $grupo (@grupos_consultados_ordenados){
		$resultado = "Ganador por sorteo del grupo ".$grupo.": Nro de Orden: ".$ganadores_por_grupo{$grupo}[0].", ".$ganadores_por_grupo{$grupo}[1]." (Nro. de Sorteo ".$ganadores_por_grupo{$grupo}[2].")\n";
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
	my $fecha_adj = &obtener_fecha_de_adjudicacion($id);
	my $fecha_salida = $fecha_adj;
	$fecha_salida =~ s/(\d{4})(\d{2})(\d{2})/\3-\2-\1/;
	$titulo = "Ganadores por Licitación ".$id." de fecha ".$fecha_salida."\n\n";
	print $titulo;

	if ($grabar) {
		my @grupos_ordenados = sort(@grupos);
		$arch_salida = $id."_L_Grd".$grupos_ordenados[0]."_Grh".$grupos_ordenados[$#grupos_ordenados]."_".$fecha_adj;
		open(SALIDA, ">$ENV{'INFODIR'}/$arch_salida");
		print SALIDA $titulo;
	}

	@grupos_consultados_ordenados = sort(keys(%ganadores_por_grupo));
	foreach $grupo (@grupos_consultados_ordenados){
		$resultado = "Ganador por licitación del grupo $grupo: Nro de Orden: $ganadores_por_grupo{$grupo}[0], $ganadores_por_grupo{$grupo}[2] con \$$ganadores_por_grupo{$grupo}[1] (Nro. de Sorteo $ganadores_por_grupo{$grupo}[3])\n";
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

sub resultado_por_grupo{
	($grabar, $id, @grupos) = @_;
	my %ganadores_por_sorteo = &ganadores_por_sorteo($id, @grupos);
	my %ganadores_por_licitacion = &ganadores_por_licitacion($id, @grupos);

	#Armo el titulo
	my $fecha_adj = &obtener_fecha_de_adjudicacion($id);
	my $fecha_salida = $fecha_adj;
	$fecha_salida =~ s/(\d{4})(\d{2})(\d{2})/\3-\2-\1/;
	$titulo = "Ganadores por Grupo en el acto de adjudicación de fecha ".$fecha_salida.", Sorteo: ".$id."\n\n";
	print $titulo;

	@grupos_consultados_ordenados = sort {$a <=> $b} (@grupos);
	foreach $grupo (@grupos_consultados_ordenados){
		if ($grabar) {
			$arch_salida = $id."_Grupo".$grupo."_".$fecha_adj;
			open(SALIDA, ">$ENV{'INFODIR'}/$arch_salida");
			print SALIDA $titulo;
		}
		$resultado_sorteo = $grupo."-".$ganadores_por_sorteo{$grupo}[0]." S (".$ganadores_por_sorteo{$grupo}[1].")\n";
		$resultado_licitacion = $grupo."-".$ganadores_por_licitacion{$grupo}[0]." L (".$ganadores_por_licitacion{$grupo}[2].")\n";
		print $resultado_sorteo;
		print $resultado_licitacion;
		print "\n";
		if ($grabar) {
			print SALIDA $resultado_sorteo;
			print SALIDA $resultado_licitacion;
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
	print "Al ejecutar Determinar ganadores:

	Se debe pasar por parametro el ID del sorteo por el cual se desea consultar.\n
	Se puede pasar la opción -g si se desea grabar las consultas que se realizen.\n
	Se puede pasar por parámetro los grupos por los que se desea consultar. Estos pueden ser:
		Un grupo
		Varios grupos
		Rangos de grupos
		*grupos para todos los grupos

	En ejecución habrá cuatro consultas porsibles:

	Resultado general del sorteo: Muestra el contenido del archivo de sorteos especificado como parámetro de forma amigable y ordenado por número de sorteo.\n
	Ganadores por sorteo: Para el o los grupos pasados como parámetro muestra, ordenado por grupo, el ganador
del sorteo.\n
	Ganadores por licitación: Para el o los grupos pasados como parámetro muestra, ordenado por grupo, el ganador
de la licitación.\n
	Resultados por grupo: Para el o los grupos pasados como parámetro muestra, ordenado por grupo, primero el
ganador del sorteo, marcado con una “S”, y luego el ganador por licitación, marcado con una “L”.

Se debe ingresar el numero de la consulta que se desea realizar o 0 si se desea salir.\n\n";
	exit;
}


# Verifico que exista el archivo 
$id = shift(@ARGV);
$archivo = &obtener_nombre_archivo_sorteo($id);
if ( $archivo eq "") {
	print "No se encuentra el archivo de sorteo con id: $id\n";
	exit;
}
# Verifico si tengo q guardar en archivo
@guardar_en_archivo = grep /^-g$/, @ARGV;
$g = 0;
if (scalar @guardar_en_archivo) {
	$g = 1;
	if (not -d $ENV{'INFODIR'}){
		mkdir($ENV{'INFODIR'});
	}
}

@grupos = &obtener_grupos(@ARGV);

%opciones = ("salir", 0, "resultado_general", 1, "ganadores_sorteo", 2, "ganadores_licitacion", 3, "resultado_por_grupo", 4);
&presentar_menu;
while ( $opcion = <STDIN> ) {
	print "\n";
	chop($opcion);
	last if $opcion eq $opciones{salir};
	if ($opcion eq $opciones{resultado_general}) {&resultado_general_sorteo($g, $id);}
	elsif ($opcion eq $opciones{ganadores_sorteo}) {&resultado_ganadores_por_sorteo($g, $id, @grupos);}
	elsif ($opcion eq $opciones{ganadores_licitacion}) {&resultado_ganadores_por_licitacion($g, $id, @grupos);}
	elsif ($opcion eq $opciones{resultado_por_grupo}) {&resultado_por_grupo($g, $id, @grupos);}
	&presentar_menu;
}

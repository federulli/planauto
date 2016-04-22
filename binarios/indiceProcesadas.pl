#!/usr/bin/perl


opendir(PROCDIR/procesadas, $ENV{'PROCDIR/procesadas'});
@files = readdir(PROCDIR/procesadas);
%hash_of_files;
foreach  $file (@files) {
	if ( -f  "$ENV{'PROCDIR/procesadas'}/$file"){
		$date = $file;
		$date =~ s/^\d*_(\d*).csv$/\1/;
		if (exists $hash_of_files{$date}) {
			push @{$hash_of_files{$date}}, $file;
		} else {
			$hash_of_files{$date}[0] = $file;
		}
	}
}
close(PROCDIR/procesadas);
@ordered_keys = sort (keys %hash_of_files);
foreach my $key (@ordered_keys){
	foreach my $file (@{$hash_of_files{$key}}) {
		print "$file ";
	}
}

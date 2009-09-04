package inc::MyBuilder;

use File::Spec;
use base 'Module::Build';

sub ACTION_build {
	my $self = shift;
	
	$self->SUPER::ACTION_build(@_);
	
	my %notes = $self->notes;
	my $path_types = $notes{'path_types'};
	
	# write the new version of SPc.pm
	open(my $config_fh, '<', File::Spec->catfile('default', 'SPc.pm')) or die $!;
	open(my $blib_config_fh, '>', File::Spec->catfile($self->blib, 'lib', 'SPc.pm')) or die $!;
	while (my $line = <$config_fh>) {
		next if ($line =~ m/# remove after install$/);
		if ($line =~ m/^sub \s+ ($path_types) \s* {/xms) {
			$line = 'sub '.$1." {'".$notes{$1}."'};"."\n"
				if exists $notes{$1};
		}
		print $blib_config_fh $line;
	}
	close($blib_config_fh);
	close($config_fh);
	
	return;
}

1;

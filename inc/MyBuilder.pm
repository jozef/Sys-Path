package inc::MyBuilder;

use File::Spec;
use IO::Any;
use base 'Module::Build';

sub ACTION_build {
	my $self = shift;
	
	$self->SUPER::ACTION_build(@_);
	
	my %notes = $self->notes;
	my $path_types = $notes{'path_types'};
	
	my $config_fh      = IO::Any->read(['default', 'SysPathConfig.pm']);
	my $blib_config_fh = IO::Any->write([$self->blib, 'lib', 'SysPathConfig.pm']);
	while (my $line = <$config_fh>) {
		if ($line =~ m/^sub \s+ ($path_types) \s* {/xms) {
			$line = 'sub '.$1." {'".$notes{$1}."'};"."\n"
				if exists $notes{$1};
		}
		print $blib_config_fh $line;
	}
	
	return;
}

1;

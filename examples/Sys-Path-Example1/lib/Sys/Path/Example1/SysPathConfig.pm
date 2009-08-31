package Sys::Path::Example1::SysPathConfig;

=head1 NAME

SysPathConfig - build-time system path configuration

=cut

use warnings;
use strict;

our $VERSION = '0.01';

use 5.010;
use feature 'state';

use File::Spec;

sub path_types {qw(
	prefix
	localstatedir
	sysconfdir
	datadir
	docdir
	cache
	log
	spool
	run
	lock
	state
)};

# sub names inspired by http://www.gnu.org/software/autoconf/manual/html_node/Installation-Directory-Variables.html#Installation-Directory-Variables
sub prefix        { use Sys::Path; Sys::Path->find_distribution_root(__PACKAGE__); };
sub localstatedir { __PACKAGE__->prefix };
sub sysconfdir    { File::Spec->catdir(__PACKAGE__->prefix, 'etc') };

sub datadir    { File::Spec->catdir(__PACKAGE__->prefix, 'share') };
sub docdir     { File::Spec->catdir(__PACKAGE__->prefix, 'doc') };
sub cache      { File::Spec->catdir(__PACKAGE__->localstatedir, 'cache') };
sub log        { File::Spec->catdir(__PACKAGE__->localstatedir, 'log') };
sub spool      { File::Spec->catdir(__PACKAGE__->localstatedir, 'spool') };
sub run        { File::Spec->catdir(__PACKAGE__->localstatedir, 'run') };
sub lock       { File::Spec->catdir(__PACKAGE__->localstatedir, 'lock') };
sub state      { File::Spec->catdir(__PACKAGE__->localstatedir, 'state') };

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut

package SPc;

=head1 NAME

SPc - build-time system path configuration

=cut

use warnings;
use strict;

our $VERSION = '0.01';

use 5.010;
use feature 'state';

use File::Spec;

sub _path_types {qw(
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

=head1 PATHS

=head2 prefix

=head2 localstatedir

=head2 sysconfdir

=head2 datadir

=head2 docdir

=head2 cache

=head2 log

=head2 spool

=head2 run

=head2 lock

=head2 state

=cut

# sub names inspired by http://www.gnu.org/software/autoconf/manual/html_node/Installation-Directory-Variables.html#Installation-Directory-Variables
sub prefix        { use Config; state $prefix = $Config::Config{'prefix'}; shift; $prefix = $_[0] if @_; return $prefix; };
sub localstatedir { use Config; state $localstatedir = $Config::Config{'prefix'} eq '/usr' ? '/var' : File::Spec->catdir($Config::Config{'prefix'}, 'var'); shift; $localstatedir = $_[0] if @_; return $localstatedir; };

sub sysconfdir { use Config; state $sysconfdir = $Config::Config{'prefix'} eq '/usr' ? '/etc' : File::Spec->catdir($Config::Config{'prefix'}, 'etc'); shift; $sysconfdir = $_[0] if @_; return $sysconfdir; };
sub datadir    { File::Spec->catdir(__PACKAGE__->prefix, 'share') };
sub docdir     { File::Spec->catdir(__PACKAGE__->prefix, 'share', 'doc') };
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

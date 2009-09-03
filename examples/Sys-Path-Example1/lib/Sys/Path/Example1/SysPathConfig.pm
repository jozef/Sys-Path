package Sys::Path::Example1::SysPathConfig;

=head1 NAME

SysPathConfig - build-time system path configuration

=cut

use warnings;
use strict;

our $VERSION = '0.01';

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

sub prefix        { use Module::Build::SysPath; Module::Build::SysPath->find_distribution_root(__PACKAGE__); };
sub localstatedir { __PACKAGE__->prefix };

sub sysconfdir { File::Spec->catdir(__PACKAGE__->prefix, 'etc') };
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

package Module::Build::SysPath;

=head1 NAME

Module::Build::SysPath - Module::Build subclass with Sys::Path ACTION_install

=head1 SYNOPSIS

    use Module::Build::SysPath;
    my $builder = Module::Build::SysPath->new(
        ...


=head1 DESCRIPTION

A subclass of L<Module::Build>. See L<Sys::Path> for description and usage.

=cut

use warnings;
use strict;

our $VERSION = '0.01';

use base 'Module::Build';
use Sys::Path;

=head2 new

Adds execution of L<Sys::Path/post_new> to L<Module::Build/new>.

=cut

sub new {
	my $class = shift;
	my $builder = $class->SUPER::new(@_);
	return Sys::Path->post_new($builder);
}

=head2 ACTION_install

Adds execution of L<Sys::Path/ACTION_post_install> to L<Module::Build/ACTION_install>.

=cut

sub ACTION_install {
	my $builder = shift;
	$builder->SUPER::ACTION_install(@_);
	Sys::Path->ACTION_post_install($builder);
}


1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut

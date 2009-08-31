package Module::Build::SysPath;

=head1 NAME

Module::Build::SysPath - Module::Build subclass with Sys::Path ACTION_install

=head1 SYNOPSIS

    use Module::Build::SysPath;
    my $builder = Module::Build::SysPath->new(
        ...


=head1 DESCRIPTION

=cut

use warnings;
use strict;

our $VERSION = '0.01';

use base 'Module::Build';
use Sys::Path;

sub new {
	my $class = shift;
	my $builder = $class->SUPER::new(@_);
	return Sys::Path->post_new($builder);
}

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

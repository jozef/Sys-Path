package Sys::Path;

=head1 NAME

Sys::Path - get/configure system paths

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 BUILD

    PERL_MM_USE_DEFAULT=1 perl Build.PL \
        --sp-prefix=/usr/local \
        --sp-sysconfdir=/usr/local/etc \
        --sp-localstatedir=/var/local

=head1 Build.PL

    use Module::Build::SysPath;
    my $builder = Module::Build::SysPath->new(
        ...

    use Module::Build;
    # update system paths during the installation
    my $builder_class = Module::Build->subclass(
        class => 'My::Builder',
        code => q{
            use Sys::Path;
            sub ACTION_install {
                my $builder = shift;
                $builder->SUPER::ACTION_install(@_);
                Sys::Path->ACTION_post_install($builder);
            }
        },
    );
    
    my $builder = $builder_class->new(
        ...


=cut

use warnings;
use strict;

our $VERSION = '0.01';

use File::Spec;
use IO::Any;

BEGIN {
    my $home = eval { local $SIG{__DIE__}; (getpwuid($>))[7] } || $ENV{HOME};
    $home ||= $ENV{HOMEDRIVE} . ($ENV{HOMEPATH} || '') if defined $ENV{HOMEDRIVE};
    if ($home) {
        my $syspath_home = File::Spec->catdir($home, '.syspath');
        if (-d $syspath_home) {
            local @INC = ($syspath_home);
            eval { require 'SysPathConfig' };
        }
    }
}
use base 'SysPathConfig';

=head1 METHODS

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

=cut

=head2 ACTION_post_install($builder [, $module_name])

Action that should be run after L<Module::Build> ACTION_install.

=cut

sub ACTION_post_install {
    my $self    = shift;
    my $builder = shift;
    my $module  = shift || $builder->module_name;

    my $path_types = join('|', $self->path_types);
    
    # normalize module name (some people write - instead of ::) and add config level
    $module =~ s/-/::/g;
    $module .= '::SysPathConfig';
    
    # get path to blib and just installed SysPathConfig.pm
    my $module_filename = $module.'.pm';
    $module_filename =~ s{::}{/}g;
    my $installed_module_filename = File::Spec->catfile(
        $builder->install_map->{File::Spec->catdir(
            $builder->blib,
            'lib',        
        )},
        $module_filename
    );
    $module_filename = File::Spec->catfile($builder->blib, 'lib', $module_filename);
    
    die 'no such file - '.$module_filename
        if not -f $module_filename;
    die 'no such file - '.$installed_module_filename
        if not -f $installed_module_filename;
    unlink $installed_module_filename;
    
    # write the new version of SysPathConfig.pm
    my $config_fh      = IO::Any->read([$module_filename]);
    my $real_config_fh = IO::Any->write([$installed_module_filename]);
    while (my $line = <$config_fh>) {
        if ($line =~ m/^sub \s+ ($path_types) \s* {/xms) {
            $line = 'sub '.$1." {'".Sys::Path->$1."'};"."\n";
        }
        print $real_config_fh $line;
    }
    close($real_config_fh);
    close($config_fh);    
}

=head2 find_distribution_root(__PACKAGE__)

Find the root folder of distribution by going up the folder structure.

=cut

sub find_distribution_root {
    my $self            = shift;
    my $module_name     = shift;

    my $module_filename = $module_name.'.pm';
    $module_filename =~ s{::}{/}g;
    $module_filename = File::Spec->rel2abs($INC{$module_filename});
    
    my @path = File::Spec->splitdir($module_filename);
    my @package_names = split('::',$module_name);
    @path = splice(@path,0,-1-@package_names);
    while (not -d File::Spec->catdir(@path, 't')) {
        pop @path;
        die 'failed to find distribution root'
            if not @path;
    }
    return File::Spec->catdir(@path);
}

1;


__END__

=head1 AUTHOR

Jozef Kutej, C<< <jkutej at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sys-path at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sys-Path>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sys::Path


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sys-Path>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sys-Path>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sys-Path>

=item * Search CPAN

L<http://search.cpan.org/dist/Sys-Path>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jozef Kutej, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Sys::Path

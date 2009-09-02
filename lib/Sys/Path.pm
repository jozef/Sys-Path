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
    use Sys::Path;
    
    # update system paths during the installation
    my $builder_class = Module::Build->subclass(
        class => 'My::Builder',
        code => q{
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
        },
    );
    
    my $builder = $builder_class->new(
        ...

=head1 NOTE

This is an experiment and lot of questions and concerns can come out about
the paths configuration. L<Module::Build> integration and the naming. And as
this is early version thinks may change. For these purposes there is a mailing
list L<http://lists.meon.sk/mailman/listinfo/sys-path>.

=head1 DESCRIPTION

This module tries to solve the problem of working with data files, configuration files,
images, logs, locks, ..., any non-F<*.pm> files within distribution tar-balls.
The default paths for file locations are based on L<http://www.pathname.com/fhs/>
(Filesystem Hierarchy Standard) if the Perl was installed in F</usr>. For
all other non-standard Perl installations or systems the default prefix is
the prefix of Perl it self. Still those are just defaults and can be changed
during C<perl Build.PL> prompting. After L<Sys::Path> is configured and installed
all modules using it can just read/use the paths set. In addition to the system
wide L<SysPathConfig> this file (F<SysPathConfig.pm>) can be added to F<$HOME/.syspath/>
folder in which case it has a preference over the system wide one.

=head2 USAGE

L<Sys::Path> primary usage is for module authors to allow them to find their
data files as during development and testing but also when installed. How?
Let's look at an example distribution L<Acme::SysPath> that needs a configuration
file an image file and a template file. See the modules

L<http://github.com/jozef/Acme-SysPath/blob/1a4b89e8239f55bee31b7f1c4fa3d69c8de7c3a4/lib/Acme/SysPath.pm>

or L<Acme::SysPath>. It has path()+template()+image() functions. While working
in the distribution tree:

    Acme-SysPath$ perl -Ilib -MAcme::SysPath -le 'print Acme::SysPath->config, "\n", Acme::SysPath->template;'
    /home/jozef/prog/Acme-SysPath/conf/acme-syspath.cfg
    /home/jozef/prog/Acme-SysPath/share/acme-syspath/tt/index.tt2

After install:

    Acme-SysPath$ perl Build.PL && ./Build && ./Build test
    Acme-SysPath$ sudo ./Build install
    Copying lib/Acme/SysPath.pm -> blib/lib/Acme/SysPath.pm
    Manifying blib/lib/Acme/SysPath.pm -> blib/libdoc/Acme::SysPath.3pm
    Installing /usr/share/acme-syspath/tt/index.tt2
    Installing /usr/share/acme-syspath/images/smile.ascii
    Installing /usr/local/share/perl/5.10.0/Acme/SysPath.pm
    Installing /usr/local/share/perl/5.10.0/Acme/SysPath/SysPathConfig.pm
    Installing /usr/local/man/man3/Acme::SysPath::SysPathConfig.3pm
    Installing /usr/local/man/man3/Acme::SysPath.3pm
    Installing /etc/acme-syspath.cfg
    Writing /usr/local/lib/perl/5.10.0/auto/Acme/SysPath/.packlist

    Acme-SysPath$ cat /usr/local/share/perl/5.10.0/Acme/SysPath/SysPathConfig.pm
    ...
    sub prefix {'/usr'};
    sub sysconfdir {'/etc'};
    sub datadir {'/usr/share'};
    ...
    
    ~$ perl -MAcme::SysPath -le 'print Acme::SysPath->config, "\n", Acme::SysPath->template;'
    /etc/acme-syspath.cfg
    /usr/share/acme-syspath/tt/index.tt2
    
    ~$ perl -MAcme::SysPath -le 'print Acme::SysPath->image;'
    ... try your self :-P

First step is to have a L<My::App::SysPathConfig>. Take one of:

L<http://github.com/jozef/Acme-SysPath/blob/a4c28e33696a23445bc08aa985b5d26affbc6345/lib/Acme/SysPath/SysPathConfig.pm>
L<http://github.com/jozef/Sys-Path/blob/c84b5406e96672b73b2f45680c8890aefb6ff41b/examples/Sys-Path-Example1/lib/Sys/Path/Example1/SysPathConfig.pm>

Then keep the needed paths and set then to your distribution taste. (someone
likes etc, someone likes F<cfg> or F<conf> or ...) Then replace the L<Module::Build>
in F<Build.PL> with L<Module::Build::SysPath>. And finally populate the F<etc/>, F<cfg/>,
F<conf/>, F<share/>, F<doc/>, ... with some useful content.

=head2 WHY?

TODO for next version...

=head2 HOW IT WORKS

TODO for next version...

=cut

use warnings;
use strict;

our $VERSION = '0.03';

use File::Spec;
use IO::Any;
use List::MoreUtils 'any';
use FindBin '$Bin';

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

    my $path_types = join('|', $self->_path_types);
    
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
    
    return;
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

=head2 post_new

Function to be invoked after L<Module::Build/new>.

=cut

sub post_new {
    my $self    = shift;
    my $builder = shift;
    my $module  = shift || $builder->module_name;

    # normalize module name (some people write - instead of ::) and add config level
    $module =~ s/-/::/g;
    $module .= '::SysPathConfig';
    
    do {
        unshift @INC, File::Spec->catdir($Bin, 'lib');
        eval "use $module"; die $@ if $@;
    };
    
    my $distribution_root = $self->find_distribution_root($module);
    
    foreach my $path_type ($module->_path_types) {
        my $sys_path = $module->$path_type;
        # skip prefix and localstatedir those are not really destination paths
        next
            if any { $_ eq $path_type } ('prefix' ,'localstatedir');
        # skip if the path doesn't exist
        next
            if not -d $sys_path;
        
        # prepare a list of files to install
        $builder->{'properties'}->{$path_type.'_files'} = {
            map {
                my $file      = $_;
                my $dest_file = $_;
                $file         =~ s/$distribution_root.//;
                $dest_file    =~ s/^$sys_path.//;
                $file => File::Spec->catfile($path_type, $dest_file)
            }
            grep { -f $_ }
            @{$builder->rscan_dir($sys_path)}
        };
        
        # set instalation paths
        $builder->{'properties'}->{'install_path'}->{$path_type} = Sys::Path->$path_type;
        
        # add build elements of the path types
        $builder->add_build_element($path_type);
    }
    
    return $builder;
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

=head2 Mailing list

L<http://lists.meon.sk/mailman/listinfo/sys-path>

=head2 The rest

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

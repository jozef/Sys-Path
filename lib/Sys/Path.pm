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
        configure_requires => {
            'Module::Build::SysPath' => 0.06,
        },
        build_requires => {
            'Module::Build::SysPath' => 0.06,
        }
        ...

    use Module::Build;
    use Sys::Path;
    
    # update system paths during the installation
    my $builder_class = Module::Build->subclass(
        class => 'My::Builder',
        code => q{ use Module::Build::SysPath; unshift @ISA, 'Module::Build::SysPath'; },
    );
    
    my $builder = $builder_class->new(
        configure_requires => {
            'Module::Build::SysPath' => 0.06,
        },
        build_requires => {
            'Module::Build::SysPath' => 0.06,
        }
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
wide L<SPc>, (F<SPc.pm>) can be added to F<$HOME/.syspath/>
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
    Installing /usr/local/share/perl/5.10.0/Acme/SysPath/SPc.pm
    Installing /usr/local/man/man3/Acme::SysPath::SPc.3pm
    Installing /usr/local/man/man3/Acme::SysPath.3pm
    Installing /etc/acme-syspath.cfg
    Writing /usr/local/lib/perl/5.10.0/auto/Acme/SysPath/.packlist

    Acme-SysPath$ cat /usr/local/share/perl/5.10.0/Acme/SysPath/SPc.pm
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

First step is to have a L<My::App::SPc>. Take:

F<lib/Acme/SysPath/SPc.pm> ||
F<examples/Sys-Path-Example1/lib/Sys/Path/Example1/SPc.pm>

Then keep the needed paths and set then to your distribution taste. (someone
likes etc, someone likes F<cfg> or F<conf> or ...) Then replace the L<Module::Build>
in F<Build.PL> with L<Module::Build::SysPath>. And finally populate the F<etc/>, F<cfg/>,
F<conf/>, F<share/>, F<doc/>, ... with some useful content.

=head2 WHY?

To place and then find files on the filesystem where they are suppose to be.
There is a Filesystem Hierarchy Standard - L<http://www.pathname.com/fhs/>:

The filesystem standard has been designed to be used by Unix distribution developers,
package developers, and system implementors. However, it is primarily intended
to be a reference and is not a tutorial on how to manage a Unix filesystem or directory
hierarchy.

L<Sys::Path> follows this standard when it is possible. Or when Perl follows.
Perl can be installed in many places. Most Linux distributions place Perl
in F</usr/bin/perl> where FHS suggest. In this case the FHS folders are
suggested in prompt when doing `C<perl Build.PL>`. In other cases for
other folders or home-dir Perl distributions L<Sys::Path> will suggest
folders under Perl install prefix. (ex. F<c:\strawerry\> for the ones using
Windows).

=head2 PATHS

Here is the list of paths. First the default FHS path, then (to compare)
a suggested path when Perl is not installed in F</usr>.

=head3 prefix

F</usr> - C<$Config::Config{'prefix'}>

=head3 localstatedir

F</var> - C<$Config::Config{'prefix'}>

=head3 sysconfdir

F</etc> - $prefix/etc

=head3 datadir

F</usr/share> - $prefix/share

=head3 docdir

F</usr/share/doc> - $prefix/share/doc

=head3 localedir

F</usr/share/locale> - $prefix/share/locale

=head3 cachedir

F</var/cache> - $localstatedir/cache

=head3 logdir

F</var/log> - $localstatedir/logdir

=head3 spooldir

F</var/spool> - $localstatedir/spool

=head3 rundir

F</var/run> - $localstatedir/rundir

=head3 lockdir

F</var/lock> - $localstatedir/lock

=head3 sharedstatedir

F</var/lib> - $localstatedir/lib

The directory for installing modifiable architecture-independent data.
http://www.pathname.com/fhs/pub/fhs-2.3.html#VARLIBVARIABLESTATEINFORMATION

=head3 webdir

F</var/www> - $localstatedir/www

=head2 USE CASES

=head3 system installation

TODO

=head3 custom perl installation

TODO

=head3 homedir installation

TODO

=head2 HOW IT WORKS

TODO for next version...

=cut

use warnings;
use strict;

our $VERSION = '0.09';

use File::Spec;

BEGIN {
    my $home = eval { local $SIG{__DIE__}; (getpwuid($>))[7] } || $ENV{HOME};
    $home ||= $ENV{HOMEDRIVE} . ($ENV{HOMEPATH} || '') if defined $ENV{HOMEDRIVE};
    if ($home) {
        my $syspath_home = File::Spec->catdir($home, '.syspath');
        if (-d $syspath_home) {
            local @INC = ($syspath_home);
            eval 'use SPc';
        }
    }
}
use base 'SPc';

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

1;


__END__

=head1 FAQ

=head2 Why "SPc" ?

1. it is short (much more than SysPatchConfig)

2. it is weird

3. it's so weird that it is uniq, so there will be no conflict. (hopefully)

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

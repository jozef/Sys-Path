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

our $VERSION = '0.08';

use base 'Module::Build';
use Sys::Path;
use List::MoreUtils 'any', 'none';
use FindBin '$Bin';
use Text::Diff 'diff';
use JSON::Util;
use Digest::MD5 qw(md5_hex);

our $sys_path_config_name = 'SPc';

=head2 new

TODO

=cut

sub new {
	my $class = shift;
	my $builder = $class->SUPER::new(@_);
    my $module  = $builder->module_name;

    # normalize module name (some people write - instead of ::) and add config level
    $module =~ s/-/::/g;
    $module .= '::'.$sys_path_config_name;
    
    do {
        unshift @INC, File::Spec->catdir($Bin, 'lib');
        eval "use $module"; die $@ if $@;
    };
    
    my $distribution_root = $builder->find_distribution_root();
    
    # map conf files to array of real paths
    my @conffiles = (
        map { File::Spec->catfile(@{$_}) }                  # convert path array to file name strings
        @{$builder->{'properties'}->{'conffiles'} || []}    # all conffiles
    );
    
    my %spc_properties = (
        'path_types' => [ $module->_path_types ],
    );
    my %rename_in_system;
    my %conffiles_in_system;
    my @writefiles_in_system;
    foreach my $path_type ($module->_path_types) {
        my $sys_path     = $module->$path_type;
        my $install_path = Sys::Path->$path_type;

        # store for install time retrieval
        $spc_properties{'path'}->{$path_type} = $install_path;

        # skip prefix and localstatedir those are not really destination paths
        next
            if any { $_ eq $path_type } ('prefix' ,'localstatedir');

        # prepare a list of files to install
        if (-d $sys_path) {
            my %files;
            foreach my $file (@{$builder->rscan_dir($sys_path)}) {
                # skip folders
                next if -d $file;
                
                my $blib_file = $file;
                my $dest_file = $file;
                $file         =~ s/$distribution_root.//;
                $dest_file    =~ s/^$sys_path/$install_path/;
                $blib_file    =~ s/^$sys_path.//;
                $blib_file    = File::Spec->catfile($path_type, $blib_file);
                
                # print 'file>  ', $file, "\n";
                # print 'bfile> ', $blib_file, "\n";
                # print 'dfile> ', $dest_file, "\n\n";
                
                if (any { $_ eq $file } @conffiles) {
                    $conffiles_in_system{$dest_file} = md5_hex(IO::Any->slurp([$file]));
                    
                    my $diff;
                    $diff = diff($file, $dest_file, { STYLE => 'Unified' })
                        if -f $dest_file;
                    if (
                        $diff                                                  # prompt when files differ
                        and $builder->changed_since_install($dest_file)        # and only if the file changed on filesystem
                    ) {
                        # prompt if to overwrite conf or not
                        if (
                            # only if the distribution conffile changed since last install
                            $builder->changed_since_install($dest_file, $file)
                            and $builder->prompt_cfg_file_changed($file, $dest_file)
                        ) {
                            $rename_in_system{$dest_file} = $dest_file.'-old';
                        }
                        else {
                            $blib_file .= '-spc';
                            $dest_file .= '-spc';
                        }
                    }
                }

                # add file the the Build.PL _files list
                $files{$file} = $blib_file;

                # make the conf and state files writeable in the system
                push @writefiles_in_system, $dest_file
                    if any { $_ eq $path_type } qw(sharedstatedir sysconfdir);                
            }
            $builder->{'properties'}->{$path_type.'_files'} = \%files;
        }
                
        # set instalation paths
        $builder->{'properties'}->{'install_path'}->{$path_type} = $install_path;
        
        # add build elements of the path types
        $builder->add_build_element($path_type);
    }
    $builder->{'properties'}->{'spc'} = \%spc_properties;
    $builder->notes('rename_in_system'     => \%rename_in_system);
    $builder->notes('conffiles_in_system'  => \%conffiles_in_system);
    $builder->notes('writefiles_in_system' => \@writefiles_in_system);
    
    return $builder;
}

=head2 ACTION_install

TODO

=cut

sub ACTION_install {
    my $builder = shift;
    my $destdir = $builder->{'properties'}->{'destdir'};

    # move system file for backup (only when really installing to system)
    if (not $destdir) {
        my %rename_in_system = %{$builder->notes('rename_in_system')};
        while (my ($system_file, $new_system_file) = each %rename_in_system) {
            print 'Moving ', $system_file,' -> ', $new_system_file, "\n";
            rename($system_file, $new_system_file) or die $!;
        }
    }

    $builder->SUPER::ACTION_install(@_);

    my $module  = $builder->module_name;

    my $path_types = join('|', @{$builder->{'properties'}->{'spc'}->{'path_types'}});
    
    # normalize module name (some people write - instead of ::) and add config level
    $module =~ s/-/::/g;
    $module .= '::'.$sys_path_config_name;
    
    # get path to blib and just installed SPc.pm
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
    
    # write the new version of SPc.pm
    open(my $config_fh, '<', $module_filename) or die $!;
    open(my $real_config_fh, '>', $installed_module_filename) or die $!;
    while (my $line = <$config_fh>) {
        next if ($line =~ m/# remove after install$/);
        if ($line =~ m/^sub \s+ ($path_types) \s* {/xms) {
            $line =
                'sub '
                .$1
                ." {'"
                .$builder->{'properties'}->{'spc'}->{'path'}->{$1}
                ."'};\n"
            ;
        }
        print $real_config_fh $line;
    }
    close($real_config_fh);
    close($config_fh);
        
    # see https://rt.cpan.org/Ticket/Display.html?id=49579
    # ExtUtils::Install is forcing 0444 so we have to hack write permition after install :-/
    foreach my $writefile (@{$builder->notes('writefiles_in_system')}) {
        chmod 0644, File::Spec->catfile($destdir || (), $writefile) or die $!;
    }
    
    # record md5sum of new distribution conffiles (only when really installing to system)
    $builder->_install_checksums(%{$builder->notes('conffiles_in_system')})
        if (not $destdir);
    
    return;
}

=head2 find_distribution_root(__PACKAGE__)

Find the root folder of distribution by going up the folder structure.

=cut

sub find_distribution_root {
    my $self            = shift;
    my $module_name     = shift || $self->module_name;
    
    my $module_filename = $module_name.'.pm';
    $module_filename =~ s{::}{/}g;
    if (not exists $INC{$module_filename}) {
        eval 'use '.$module_name;
        die $@ if $@;
    }
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

sub prompt_cfg_file_changed {
    my $self     = shift;
    my $src_file = shift;
    my $dst_file = shift;

    my $answer = '';
    while (none { $answer eq $_ } qw(Y I N O) ) {
        print qq{
Installing new version of config file $dst_file ...

Configuration file `$dst_file'
 ==> Modified (by you or by a script) since installation.
 ==> Package distributor has shipped an updated version.
   What would you like to do about it ?  Your options are:
    Y or I  : install the package maintainer's version
    N or O  : keep your currently-installed version
      D     : show the differences between the versions
      Z     : background this process to examine the situation
 The default action is to keep your current version.
};
    
        $answer = uc $self->prompt('*** '.$dst_file.' (Y/I/N/O/D/Z) ?', 'N');
        if ($answer eq 'D') {
            print "\n\n";
            print diff($src_file, $dst_file, { STYLE => 'Unified' });
            print "\n";
        }
        elsif ($answer eq 'Z') {
            print "Type `exit' when you're done.\n";
            system('bash');
        }
    }

    return 1 if any { $answer eq $_ } qw(Y I);
    return 0;
}

sub changed_since_install {
    my $self      = shift;
    my $dest_file = shift;
    my $file      = shift || $dest_file;

    my %files_checksums = $self->_install_checksums;
    my $checksum = md5_hex(IO::Any->slurp([$file]));
    $files_checksums{$dest_file} ||= '';
    return $files_checksums{$dest_file} ne $checksum;
}

sub _install_checksums {
    my $self = shift;
    my @args = @_;
    my $checksums_filename = File::Spec->catfile(
        SPc->sharedstatedir,
        'syspath',
        'install-checksums.json'
    );

    if (@args) {
        print 'Updating ', $checksums_filename, "\n";
        my %conffiles_md5 = (
            $self->_install_checksums,
            @args,
        );
        JSON::Util->encode(\%conffiles_md5, [ $checksums_filename ]);
        return %conffiles_md5;
    }
    
    JSON::Util->encode({}, [ $checksums_filename ])
        if not -f $checksums_filename;
    
    return %{JSON::Util->decode([ $checksums_filename ])};
}

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut

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

our $VERSION = '0.07';

use base 'Module::Build';
use Sys::Path;
use List::MoreUtils 'any';
use FindBin '$Bin';
use IO::Any;

our $sys_path_config_name = 'SPc';

=head2 new

Adds execution of L<Sys::Path/post_new> to L<Module::Build/new>.

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

=head2 ACTION_install

Adds execution of L<Sys::Path/ACTION_post_install> to L<Module::Build/ACTION_install>.

=cut

sub ACTION_install {
	my $builder = shift;
	$builder->SUPER::ACTION_install(@_);

    my $module  = $builder->module_name;

    my $path_types = join('|', Sys::Path->_path_types);
    
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
    my $config_fh      = IO::Any->read([$module_filename]);
    my $real_config_fh = IO::Any->write([$installed_module_filename]);
    while (my $line = <$config_fh>) {
        next if ($line =~ m/# remove after install$/);
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


1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut

use strict;
use warnings;

use 5.010;

use inc::MyBuilder;

use FindBin '$Bin';
use lib File::Spec->catdir($Bin, 'default');
use SysPathConfig;

my $builder = inc::MyBuilder->new(
    module_name         => 'Sys::Path',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/Sys/Path.pm',
    requires => {
        'File::Spec' => 0,
        'IO::Any'    => 0,
    },
    build_requires => {
        'Test::More'        => 0,
    },
    add_to_cleanup      => [ 'Sys-Path-*' ],
    create_makefile_pl => 'traditional',
    create_readme       => 1,
    sign                => 1,
    get_options         => {
        'sp-prefix'        => { type => '=s' },
        'sp-localstatedir' => { type => '=s' },
        'sp-sysconfdir'    => { type => '=s' },
        'sp-datadir'       => { type => '=s' },
        'sp-docdir'        => { type => '=s' },
        'sp-cache'         => { type => '=s' },
        'sp-log'           => { type => '=s' },
        'sp-spool'         => { type => '=s' },
        'sp-run'           => { type => '=s' },
        'sp-lock'          => { type => '=s' },
        'sp-state'         => { type => '=s' },
    },
);

my @path_types = SysPathConfig->path_types;
$builder->notes('path_types' => join('|', @path_types));

foreach my $path_type (@path_types) {
    my $path = $builder->args('sp-'.$path_type);
    $path = $builder->prompt($path_type, SysPathConfig->$path_type)
        if not $path;
    SysPathConfig->$path_type($path);
    $builder->notes($path_type => $path);
    print $path_type, ' set to: ', $path, "\n";
}

$builder->create_build_script();

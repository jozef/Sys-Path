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
);

my @path_types = SysPathConfig->path_types;
$builder->notes('path_types' => join('|', @path_types));

foreach my $path_type (@path_types) {
    my $path = $builder->prompt($path_type, SysPathConfig->$path_type);
    SysPathConfig->$path_type($path);
    $builder->notes($path_type => $path);
}

$builder->create_build_script();

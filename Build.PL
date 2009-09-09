use strict;
use warnings;

use inc::MyBuilder;

use FindBin '$Bin';
use lib File::Spec->catdir($Bin, 'default');
use SPc;

my $builder = inc::MyBuilder->new(
    module_name         => 'Sys::Path',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/Sys/Path.pm',
    requires => {
        'File::Spec'      => 0,
        'List::MoreUtils' => 0,
        'Text::Diff'      => 0,
        'JSON::Util'      => 0,
        'Digest::MD5'     => 0,
        'Text::Diff'      => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Sys-Path-*' ],
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
    meta_merge => {
        resources => {
            repository => 'git://github.com/jozef/Sys-Path.git',
            bugtracker => 'http://github.com/jozef/Sys-Path/issues',
        },
        keywords => [ qw/ system paths instalation deployment applications / ],
    },
    sharedstatedir_files => {
        'varlib/syspath/install-checksums.json' => 'sharedstatedir/syspath/install-checksums.json',
    },
);

my @path_types = SPc->_path_types;
$builder->notes('path_types' => join('|', @path_types));

foreach my $path_type (@path_types) {
    my $path = $builder->args('sp-'.$path_type);
    $path = $builder->prompt($path_type, SPc->$path_type)
        if not $path;
    SPc->$path_type($path);
    $builder->notes($path_type => $path);
    print $path_type, ' set to: ', $path, "\n";
}

$builder->{'properties'}->{'install_path'}->{'sharedstatedir'} = SPc->sharedstatedir;
$builder->add_build_element('sharedstatedir');

$builder->create_build_script();

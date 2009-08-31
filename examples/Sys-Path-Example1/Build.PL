use strict;
use warnings;
use Module::Build;

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
            return Sys::Path->ACTION_post_install($builder);
        }
    },
);
    
my $builder = $builder_class->new(
    module_name         => 'Sys::Path::Example1',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/Sys/Path/Example1.pm',
    build_requires => {
        'Test::More' => 0,
        'Cwd'        => 0,
    },
    add_to_cleanup      => [ 'Sys-Path-Example1-*' ],
);

$builder->create_build_script();

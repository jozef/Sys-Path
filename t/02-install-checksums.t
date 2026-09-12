#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use File::Path 'make_path';
use File::Spec;
use File::Temp;
use Time::HiRes 'usleep';

use FindBin '$Bin';
use lib File::Spec->catfile($Bin, '..', 'lib');

use Sys::Path;
use Sys::Path::SPc;

my $tmp_dir = File::Temp->newdir();
my $localstatedir = File::Spec->catdir($tmp_dir, 'var');
my $sharedstatedir = File::Spec->catdir($localstatedir, 'lib');
my $registry_dir = File::Spec->catdir($sharedstatedir, 'syspath');
make_path($registry_dir);
Sys::Path::SPc->localstatedir($localstatedir);

my $worker_count = 12;
pipe(my $ready_reader, my $ready_writer) or die "pipe failed: $!";
pipe(my $start_reader, my $start_writer) or die "pipe failed: $!";
my @children;

for my $worker (1 .. $worker_count) {
    my $pid = fork();
    die "fork failed: $!" if not defined $pid;
    if ($pid == 0) {
        close $ready_reader;
        close $start_writer;
        syswrite($ready_writer, '.', 1) == 1
            or die "ready signal failed: $!";
        sysread($start_reader, my $signal, 1) == 1
            or die "start signal failed: $!";
        Sys::Path->install_checksums(
            "worker-$worker" => "checksum-$worker",
        );
        exit 0;
    }
    push @children, $pid;
}

close $ready_writer;
close $start_reader;
my $ready = '';
while (length($ready) < $worker_count) {
    my $bytes_read = read(
        $ready_reader,
        $ready,
        $worker_count - length($ready),
        length($ready),
    );
    die "failed to synchronize workers: $!"
        if not defined($bytes_read) or $bytes_read == 0;
}
syswrite($start_writer, 'x' x $worker_count, $worker_count) == $worker_count
    or die "failed to release workers: $!";
close $start_writer;

my $children_ok = 1;
for my $pid (@children) {
    waitpid($pid, 0);
    $children_ok &&= ($? == 0);
}
ok($children_ok, 'concurrent checksum writers exit successfully');

my %checksums = Sys::Path->install_checksums;
is_deeply(
    \%checksums,
    { map { ("worker-$_" => "checksum-$_") } 1 .. $worker_count },
    'concurrent disjoint checksum updates are all retained',
);

my $registry_file = File::Spec->catfile(
    $registry_dir,
    'install-checksums.json',
);
my $temporary_file = $registry_file.'..TMP';
ok(-f $registry_file.'.lock', 'checksum updates use a stable lock file');

my %large_update = map { ("large-$_" => 'x' x 500) } 1 .. 20_000;
my $reader_writer = fork();
die "fork failed: $!" if not defined $reader_writer;
if ($reader_writer == 0) {
    Sys::Path->install_checksums(%large_update);
    exit 0;
}
wait_for_file($temporary_file, $reader_writer);
my %during_update = Sys::Path->install_checksums;
waitpid($reader_writer, 0);
is($?, 0, 'writer observed by a concurrent reader exits successfully');
is(
    $during_update{'large-20000'},
    'x' x 500,
    'a reader waits for an active update and reads complete JSON',
);

Sys::Path->install_checksums('stable' => 'before-interruption');
my $interrupted_writer = fork();
die "fork failed: $!" if not defined $interrupted_writer;
if ($interrupted_writer == 0) {
    Sys::Path->install_checksums(
        map { ("interrupted-$_" => 'y' x 500) } 1 .. 20_000,
    );
    exit 0;
}
wait_for_file($temporary_file, $interrupted_writer);
kill 'KILL', $interrupted_writer;
waitpid($interrupted_writer, 0);
my %after_interruption = Sys::Path->install_checksums;
is(
    $after_interruption{'stable'},
    'before-interruption',
    'an interrupted publication leaves the previous registry readable',
);

done_testing();

sub wait_for_file {
    my ($filename, $pid) = @_;
    for (1 .. 1_000) {
        return if -f $filename;
        die "writer exited before creating $filename"
            if waitpid($pid, 1) == $pid;
        usleep(10_000);
    }
    die "timed out waiting for $filename";
}

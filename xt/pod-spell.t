use Test::More;

if (!$ENV{TEST_SPELLING}) {
    plan skip_all => 
      "Set the environment variable TEST_SPELLING to enable this test.";
}

eval 'use Test::Spelling;';

plan skip_all => "Test::Spelling required for testing POD spelling"
    if $@;

add_stopwords(qw(
	Jozef Kutej
	OFC
	API
	JSON
	json
	TBD
	html
	RT
	CPAN
	AnnoCPAN
	SysPathConfig
	datadir
	docdir
	localstatedir
	sysconfdir
	cachedir
	localedir
	lockdir
	logdir
	rundir
	sharedstatedir
	spooldir
	webdir
	srvdir
	TODO
	SPc
	FAQ
	FHS
	IRC
	SysPatchConfig
	autoconf
	blog
	js
));
all_pod_files_spelling_ok();

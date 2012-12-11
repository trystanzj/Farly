use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME               => 'Farly',
	VERSION_FROM       => 'lib/Farly.pm',
	LICENSE            => 'gpl',
    META_MERGE => {
         resources => {
            license     => 'http://www.gnu.org/licenses/gpl-3.0.html',
            repository  => 'https://github.com/trystanzj/Farly',
        },
    },
	BUILD_REQUIRES     => { 'ExtUtils::MakeMaker' => 6.62,
		                    'Test::Simple'        => 0,
		                    'Test::More'          => 0,
		                  },
	CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 6.62, },
	PREREQ_PM          => {
		#non-core
		'Object::KVC'       => 0.04,
		'Parse::RecDescent' => 1.965001,
		'Log::Log4perl'     => 1.35,
		'Template'          => 2.22,
		#core
		'Carp'              => 0,
		'Config'            => 0,		
		'Cwd'               => 0,
		'DynaLoader'        => 0,
		'Exporter'          => 0,
		'Exporter::Heavy'   => 0,
		'Fcntl'             => 0,
		'File::Basename'    => 0,
		'File::Path'        => 0,
		'File::Spec'        => 0,
		'File::Spec::Unix'  => 0,
		'File::Spec::Win32' => 0,
		'IO'                => 0,
		'IO::File'          => 0,
		'IO::Handle'        => 0,
		'IO::Seekable'      => 0,
		'List::Util'        => 0,
		'Scalar::Util'      => 0,
		'SelectSaver'       => 0,
		'SelfLoader'        => 0,
		'Symbol'            => 0,
		'Sys::Hostname'     => 0,
		'Text::Balanced'    => 0,
		'Time::HiRes'       => 0,
	},
	(
		$] >= 5.005
		? (
			ABSTRACT => 'Farly - Firewall Analysis and Rewrite LibrarY',
			AUTHOR   => 'Trystan Johnson'
		  )
		: ()
	),
);

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Decision::Depends',
    'VERSION_FROM'	=> 'Depends.pm', # finds $VERSION
    'PMLIBDIRS'		=> [ 'Depends' ],
    'PREREQ_PM'		=> { YAML => 0,
			     Test::More => 0,
			   }, # e.g., Module::Name => 1.1
);

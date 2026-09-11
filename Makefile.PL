use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Protocol::IR::Code',
    ABSTRACT     => 'Modular framework for decoding, converting, and encoding IR remote control signals',
    AUTHOR       => 'Brett T. Warden <bwarden@cpan.org>',
    VERSION_FROM => 'lib/Protocol/IR/Code.pm',
    LICENSE      => 'lgpl_2_1',
    MIN_PERL_VERSION => '5.010',
    EXE_FILES    => [qw(bin/ir-irdb2wig bin/ir-convert bin/ir-tasmota2wig)],
    PREREQ_PM    => {
        'JSON::PP'   => '2.00',
        # Core since Perl 5.14; the bin/ tools use it to fetch IRDB files.
        'HTTP::Tiny' => '0.017',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            license    => ['https://www.gnu.org/licenses/lgpl-2.1.html'],
            # TODO: point these at the real repository before the first
            # public release.
            repository => {
                type => 'git',
                url  => 'https://github.com/USER/ir-code.git',
                web  => 'https://github.com/USER/ir-code',
            },
            bugtracker => {
                web => 'https://github.com/USER/ir-code/issues',
            },
        },
    },
);

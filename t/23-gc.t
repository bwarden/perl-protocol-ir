#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use Protocol::IR::Converter;

my $converter = Protocol::IR::Converter->new();

my $gc_json = <<'JSON';
{
  "commands": [
    {
      "keycode": "G:Memorex 32 Bit:()(0xC10000FF)():3",
      "name": "PowerToggle",
      "pronto": "0000 006D 0022 0000 0156 00AB 0017 003D 0017 003D 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 003D 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 003D 0017 003D 0017 003D 0017 003D 0017 003D 0017 003D 0017 003D 0017 003D 0017 0663",
      "protocol": "Memorex 32 Bit"
    },
    {
      "keycode": "G:Memorex 32 Bit:()(0xC10040BF)():3",
      "name": "VolumeUp",
      "pronto": "0000 006D 0022 0000 0156 00AB 0017 003D 0017 003D 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 003D 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 003D 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 003D 0017 0013 0017 003D 0017 003D 0017 003D 0017 003D 0017 003D 0017 003D 0017 0663",
      "protocol": "Memorex 32 Bit"
    }
  ]
}
JSON

my $codes = $converter->import_format('GCIR', $gc_json);
is(scalar(@$codes), 2, 'imported two commands');

my ($power, $vol) = @$codes;
is($power->alias,    'PowerToggle', 'alias comes from name');
is($power->protocol, 'NEC',         'NEC decoded from the Pronto payload');
is($power->bits,     32,            '32-bit');
is($power->address,  131,           'address 131');
is($power->subaddress, 0,           'subaddress 0');
is($power->command,  0,             'command 0');
is($power->data,      0x830000FF,   'display-form data');
is($vol->alias,       'VolumeUp',   'second command alias');
is($vol->command,     2,            'second command');
is($vol->data,        0x830002FD,   'second display-form data');

my $global_cache = $converter->import_format('GlobalCache', $gc_json);
is($global_cache->[0]->alias, 'PowerToggle', 'GlobalCache is an alias for GCIR');

my $via_wig = $converter->import_format('WIG', $gc_json);
is(scalar(@$via_wig), 2, 'wig entry point imports a GC export interchangeably');
is($via_wig->[0]->alias, 'PowerToggle', 'WIG import uses the GC command name');
is($via_wig->[0]->data,  0x830000FF,   'WIG import decodes the same payload');
is($via_wig->[1]->command, 2,          'WIG import second command');

# Pronto export is pulse-quantized, so re-importing the export must
# preserve the decoded fields (as the wig tests establish for the payload).
my $round = $converter->import_format('Pronto', $converter->export_code($power, 'Pronto'));
is($round->protocol,   'NEC',         'round-trip keeps protocol');
is($round->address,    131,           'round-trip keeps address');
is($round->command,    0,             'round-trip keeps command');
is($round->data,       0x830000FF,    'round-trip keeps data');

# Import from a file path.
my ($fh, $path) = tempfile();
print {$fh} $gc_json;
close $fh;
my $from_file = $converter->import_format('GCIR', $path);
is(scalar(@$from_file), 2, 'import from file path');

my $wig_guard = $converter->import_format('WIG', $path);
is($wig_guard->[0]->alias, 'PowerToggle', 'WIG gateway also reads from a path');

# Error handling.
eval { $converter->import_format('GCIR', undef); };
like($@, qr/^No GC input/, 'rejects missing input');

eval { $converter->import_format('GCIR', '{ not json'); };
like($@, qr/^Invalid GC JSON/, 'rejects invalid JSON');

eval { $converter->import_format('GCIR', '[1,2,3]'); };
like($@, qr/^GC top level must be a JSON object/, 'rejects non-object');

eval { $converter->import_format('GCIR', '{}'); };
like($@, qr/^GC requires a commands list/, 'rejects missing commands');

eval { $converter->import_format('GCIR', '{"commands": []}'); };
like($@, qr/^GC requires a commands list/, 'rejects empty commands');

eval { $converter->import_format('GCIR', '{"commands": [{"name": "X"}]}'); };
like($@, qr/missing its pronto hex/, 'rejects missing pronto');

eval { $converter->import_format('GCIR', '{"commands": [{"name": "", "pronto": "0000 006D 0022 0000"}]}'); };
like($@, qr/missing its name/, 'rejects empty name');

eval { $converter->import_format('GCIR', '{"commands": [{"name": "X", "pronto": "nonsense"}]}'); };
like($@, qr/cannot be decoded/, 'rejects undecodable pronto');

# A wig-shaped document is not treated as GC.
eval { $converter->import_format('GCIR', '{"format": "hair-wig/3", "name": "R", "signals": []}'); };
like($@, qr/^GC requires a commands list/, 'a wig document is not GC');

done_testing;
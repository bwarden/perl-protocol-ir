# Protocol::IR

Perl protocol library and CLI tools for IR remote codes, split out of the
former `ir-remote-tools` monorepo.

`Protocol::IR` is a CPAN distribution rooted at this repository. Main docs
are the POD in `lib/`; see `SOURCES.md` for how protocol knowledge was
sourced.

## Layout

| Path          | Contents |
|---------------|----------|
| `lib/`        | `Protocol::IR::Code` (a decoded IR signal), `Protocol::IR::Converter` (protocol identification + format conversion), format handlers (CSV/LIRC/Mode2/Pronto/Tasmota/WIG/Global Cache JSON) and protocol handlers (NEC family, JVC, Samsung, Panasonic, MWM framing). |
| `bin/`        | CLI tools: `ir-convert`, `ir-irdb2wig`, `ir-tasmota2wig`. |
| `t/`          | Test suite (ExtUtils::MakeMaker). |
| `docs/`       | (unused; the shared MWM protocol docs live in the python-mwm repo) |

MWM ("Made With Magic" / Glow With The Show) is covered here only at the
basic framing level: encoding 2400 bps serial over 38 kHz as raw timings
(`lib/Protocol/IR/Proto/MWM.pm`). Command-level detail, the color/probe
tables, and the rig tools (`mwm-probe`, `ir-mwm-send`, `MWMProbe`) live in
the python-mwm repo, where the equivalent tooling is ported to Python.

## Build and test

```sh
perl Makefile.PL
make
make test
```

CI (`ci-perl.yml`) runs a Perl test matrix; `release-perl.yml` publishes
`IR-Code` to PAUSE on `v*` tags.

## Trademark notice

This repository exists solely to enable interoperability with
independently purchased hardware. It is an independent community project:
it is not supplied by, authorized by, affiliated with, or endorsed by The
Walt Disney Company or any other rights holder. "Made With Magic",
"Glow With The Show", and all related names and marks are trademarks of
their respective owners, referenced here only to identify interoperable
functionality.
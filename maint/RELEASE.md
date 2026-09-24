# Release process

This distribution is built, versioned, and released with
[Minilla](https://metacpan.org/pod/Minilla). The build (a CPAN-ready tarball
assembled from the git-tracked file set) is split out of the Makefile-based
`maint/release.sh` and lives in the `minil` CLI.

## Layout

| Path          | Contents |
|---------------|----------|
| `lib/`        | `Protocol::IR::Code` (a decoded IR signal), `Protocol::IR::Converter` (protocol identification + format conversion), format handlers (CSV/LIRC/Mode2/Pronto/Tasmota/WIG/Global Cache JSON) and protocol handlers (NEC family, JVC, Samsung, Panasonic, MWM framing). |
| `bin/`        | CLI tools: `ir-convert`, `ir-irdb2wig`, `ir-tasmota2wig` (installed as the dist's EXE_FILES). |
| `t/`          | Install-mode tests. `t/07-author.t` additionally cross-checks MANIFEST vs the tree and module versions when `AUTHOR_TESTING=1`. |
| `maint/`      | This document. |
| `docs/`       | Unused; the shared MWM protocol docs live in the python-mwm repo. |

MWM ("Made With Magic" / Glow With The Show) is covered here only at the
basic framing level: encoding 2400 bps serial over 38 kHz as raw timings
(`lib/Protocol/IR/Proto/MWM.pm`). Command-level detail, the color/probe
tables, and the rig tools live in the python-mwm repo.

## One-time setup

Minilla needs a `~/.pause` file before it can upload the tarball:

```ini
user {{YOUR_PAUSE_ID}}
password {{YOUR_PAUSE_API_TOKEN}}
```

(`minil release` prompts for confirmation and, on success, tags the release,
commits the generated metadata, and pushes to the `origin` remote.)

## Test modes

Two kinds of checks exist, and CI runs both:

- **Install-mode tests** (`make test`, i.e. `AUTHOR_TESTING` unset). This is
  exactly what a user's `cpanm Protocol::IR::Code` runs. **Every one of these
  must pass, always** — a failure here breaks installation for users.
- **Author tests** (`AUTHOR_TESTING=1 make test`). These check the
  distribution itself — POD validity (`t/06-pod.t`), MANIFEST in sync and
  consistent module versions (`t/07-author.t`). They are skipped during
  install, so a failure costs nothing to users.

The GitHub Actions workflow `.github/workflows/ci-perl.yml` runs both modes
on every PR and push to `main`, and finishes by proving `minil dist` builds
a tarball from the gathered file set.

## Making a release

All changes must be committed first (the working tree must be clean apart
from a `Changes` entry under `{{$NEXT}}`).

1. **Write the change log.** Put the notes for the upcoming release under the
   `{{$NEXT}}` heading at the top of `Changes`. Minilla refuses to release
   until at least one indented line sits there:

   ```sh
   minil test --release
   ```

2. **Build and release.** `minil release` bumps every module's `$VERSION` in
   one step (it proposes the next version; accept or type a new one), stamps
   `Changes` with the version and timestamp, regenerates `Makefile.PL`,
   `META.json`, and `README.md`, runs the full test suite, builds
   `Protocol-IR-Code-<version>.tar.gz`, uploads it to PAUSE, tags it
   `v<version>`, and pushes both the commit and tag:

   ```sh
   minil release
   ```

   For the first conversion, or to check the flow without touching CPAN:

   ```sh
   FAKE_RELEASE=1 minil release
   ```

   `FAKE_RELEASE` skips only the upload, not the git tag/commit/push.

3. **Verify** the release on CPAN and watch CPAN Testers come back green.

## Alternative: tag-triggered release

Pushing a `v*` tag (e.g. `minil release` does this automatically, or
`git tag v0.08 && git push --tags`) triggers
`.github/workflows/release-perl.yml`, which re-runs all tests (author tests
included), verifies the tag matches the distribution version, builds the
tarball with `minil dist`, and uploads it to PAUSE. It needs two repository
secrets:

- `PAUSE_USER` — your PAUSE ID
- `PAUSE_PASSWORD` — your PAUSE API token (account settings on pause.perl.org)

For a purely manual upload instead:

```sh
cpanm --notest CPAN::Uploader
cpan-upload --user <PAUSE_ID> --password <API_TOKEN> Protocol-IR-Code-X.XX.tar.gz
```
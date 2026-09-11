# Release process

This distribution is built with `ExtUtils::MakeMaker`. The release steps are:

## 1. Test modes

Two kinds of checks exist, and CI and the release script run both:

- **Install-mode tests** (`make test`, i.e. `AUTHOR_TESTING` unset). This is
  exactly what a user's `cpanm Protocol::IR::Code` runs. **Every one of these must
  pass, always** — a failure here breaks installation for users.
- **Author tests** (`AUTHOR_TESTING=1 make test`). These check the
  distribution itself — POD validity (`t/06-pod.t`), MANIFEST in sync and
  consistent module versions (`t/07-author.t`). They are skipped during
  install, so a failure costs nothing to users. They exist so that problems
  are caught at development/PR time, where they can actually be fixed.

The GitHub Actions workflow `.github/workflows/ci.yml` runs both modes
(plus `make disttest` and `make dist`) on every PR and push to `main`.

## 2. Bump the version

The distribution version comes from `lib/IR/Code.pm` (`VERSION_FROM`).
Every module shares the same version. Bump it and build the release with
the helper:

```sh
maint/release.sh 0.04 "Added ..."
```

This bumps all modules, adds a `Changes` entry, runs install-mode tests,
author tests, `make disttest`, and finally produces `make dist`
(`IR-Code-<version>.tar.gz`). It never commits, tags, or uploads.

## 3. Commit and tag

```sh
git add -A
git commit -m "Bump version to 0.04"
git tag v0.04
git push --tags
```

## 4. Upload to CPAN

Two options:

- **Automatic:** pushing a `v*` tag triggers
  `.github/workflows/release.yml`, which re-runs all tests, verifies the tag
  matches the distribution version, builds the tarball, and uploads it to
  PAUSE. It needs two repository secrets:
  - `PAUSE_USER` — your PAUSE ID
  - `PAUSE_PASSWORD` — your PAUSE API token (account settings on pause.perl.org)

- **Manual:**
  ```sh
  cpanm --notest CPAN::Uploader
  cpan-upload --user <PAUSE_ID> --password <API_TOKEN> IR-Code-0.04.tar.gz
  ```

Then verify the release on CPAN and make sure the automated tester
(CPAN Testers) results come back green.

#!/usr/bin/env bash
# maint/release.sh - bump the version and build/test the CPAN distribution.
#
# Usage:
#   maint/release.sh                 # build + test the current version
#   maint/release.sh 0.03            # bump every module to 0.03, then build + test
#   maint/release.sh 0.03 "summary"  # ... with a one-line Changes entry
#
# The script always runs, in order:
#   1. install-mode tests   (make test, no AUTHOR_TESTING)
#   2. author tests         (AUTHOR_TESTING=1 make test)
#   3. disttest             (unpacks the tarball and tests it)
#   4. make dist            (produces IR-Code-<version>.tar.gz)
#
# It never commits, tags, or uploads; see maint/RELEASE.md for those steps.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

NEW_VERSION="${1:-}"
NOTE="${2:-}"

# --- current version (single source of truth: lib/IR/Code.pm) ------------
CURRENT="$(perl -Ilib -MProtocol::IR::Code -e 'print $Protocol::IR::Code::VERSION')"
echo "Current version: $CURRENT"

if [ -n "$NEW_VERSION" ]; then
    if ! [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+$ ]]; then
        echo "error: version must look like 0.03" >&2
        exit 1
    fi
    if ! git diff --quiet -- lib Changes Makefile.PL MANIFEST MANIFEST.SKIP; then
        echo "error: uncommitted changes in shipped files; commit them first" >&2
        exit 1
    fi

    # Keep every module in step with the distribution version.
    perl -pi -e "s/^our \\\$VERSION = '[0-9.]*';/our \\\$VERSION = '$NEW_VERSION';/" \
        lib/IR/*.pm lib/IR/*/*.pm

    # Prepend a Changes entry.
    {
        echo "Revision history for Protocol::IR::Code"
        echo ""
        echo "$NEW_VERSION    $(date +%F)"
        if [ -n "$NOTE" ]; then
            echo "    - $NOTE"
        else
            echo "    - TBD"
        fi
        echo ""
        tail -n +3 Changes
    } > Changes.new
    mv Changes.new Changes

    echo "Bumped to $NEW_VERSION (Changes entry added; edit the TBD line if needed)"
fi

# --- MANIFEST must be in sync, or `make dist` silently drops files ---------
MANIFEST_WARN="$(perl -MExtUtils::Manifest -e 'print join("\n", ExtUtils::Manifest::manicheck())' 2>&1 || true)"
if [ -n "$MANIFEST_WARN" ]; then
    echo "error: MANIFEST is out of sync:" >&2
    echo "$MANIFEST_WARN" >&2
    echo "fix with: perl -MExtUtils::Manifest -e 'ExtUtils::Manifest::mkmanifest()'" >&2
    exit 1
fi

# --- build and test --------------------------------------------------------
perl Makefile.PL
make
echo
echo "--- install-mode tests (what a user's cpanm runs) ---"
make test
echo
echo "--- author tests (AUTHOR_TESTING=1) ---"
AUTHOR_TESTING=1 make test
echo
echo "--- disttest (tests the distribution tarball) ---"
make disttest
echo
echo "--- dist ---"
make dist

TARBALL="$(ls -t IR-Code-*.tar.gz | head -1)"
echo
echo "Distribution ready: $TARBALL"
echo "Next steps (see maint/RELEASE.md):"
echo "  1. git add -A && git commit -m 'Bump version to $NEW_VERSION'"
echo "  2. git tag v$NEW_VERSION && git push --tags"
echo "     (a v* tag triggers the Release to CPAN workflow)"
echo "  3. or upload manually: cpan-upload --user YOUR_ID --password YOUR_TOKEN $TARBALL"

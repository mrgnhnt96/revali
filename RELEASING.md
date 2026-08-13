# Releasing

How a release decides what ships. Durable reference — it does not change
between releases.

Nothing is outstanding — the 08.13.26 release published nine packages and its
checklist was deleted once applied. If a round is in flight, that round's
outstanding edits belong in a scratch file that is deleted when it ships, not
in this one.

## How the release decides what to publish

`scripts/lib/prep_for_publish.dart` is the release. It:

1. Discovers every package **without** `publish_to: none`, ignoring
   `examples/`, `.revali/`, `test/` and `small_test/`.
2. **Exits 1 if any discovered package has no `LATEST_CHANGELOG.md` entry.**
3. Publishes only the packages whose `LATEST_CHANGELOG.md` version **differs
   from** their `pubspec.yaml` version, then writes that version into the
   pubspec and rewrites every dependent's constraint to `^<new version>`.

Two consequences worth holding onto:

- **Equal versions mean skipped.** A package with real changes whose changelog
  version still matches its pubspec is silently not published.
- **A dependent's constraint is only rewritten if that dependent is itself
  in the release.** Publishing a major without re-releasing its dependents
  leaves them pinned to the old range, and the published set stops resolving.

## Deliberately not published

**`og_card`** is marked `publish_to: none`. It is a build-time tool for
`doc-site/tool/gen_og_cards.dart` and nothing else depends on it.

It was previously *discoverable* — no `publish_to`, full pub metadata — which
made it a release hazard in both directions: with no changelog entry the
release script exited 1 before publishing anything, and with one it was a
version bump away from going to pub.dev unintentionally. Its pub metadata and
`LICENSE` are kept, so publishing later is a one-line change; it would also
want a `README.md` and `CHANGELOG.md`, which it still lacks.

## Before running it

- `./scripts/run_all_tests.sh` must pass. `sip run publish` calls it now; it
  previously used `sip test --recursive`, which exits 0 having run nothing.
- `prep_for_publish.dart` runs `pub publish --force`. There is **no
  confirmation step**, so `LATEST_CHANGELOG.md` is the only thing standing
  between a wrong version and pub.dev.
- Versions are edited in `LATEST_CHANGELOG.md`, never in a `pubspec.yaml`.
  The script writes the pubspec; editing it by hand makes the package look
  unchanged and it silently will not publish.

## Common failure modes

Each of these has actually happened in this repo:

- **A changed package does not publish** because its changelog version still
  equals its pubspec version.
- **The published set stops resolving** because a major shipped while a
  dependent stayed behind on the old constraint. See the `revali_swagger`
  1.1.0 and `revali_client_gen` 2.3.0 entries — both are retroactive fixes
  for exactly this.
- **The whole release aborts before publishing anything** because a
  discoverable package has no changelog entry at all (step 2 above).

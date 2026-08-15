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
3. Asks pub.dev which versions of each package are actually published.
4. Prints a **release plan** covering every discovered package, then asks for
   confirmation before touching anything.
5. Publishes only the packages whose `LATEST_CHANGELOG.md` version **differs
   from** their `pubspec.yaml` version, then writes that version into the
   pubspec and rewrites every dependent's constraint to `^<new version>`.

Two consequences worth holding onto:

- **Equal versions mean skipped**, and that is usually correct: after a
  successful publish the pubspec is bumped to match, so every package not
  being released sits equal. What used to be dangerous is that the skip was
  *silent* — "correctly up to date" and "someone forgot to bump the changelog,
  so this release did nothing" produced identical output, namely none, while
  the run still exited 0.

  The plan now distinguishes them by asking the registry, so each package
  reads as one of:

  | Marker | Meaning |
  |---|---|
  | `PUBLISH` | changelog version differs from pubspec — this one ships |
  | `current` | versions agree **and** the registry has that version |
  | `MISSING` | versions agree and the registry does **not** — nothing will publish it, and nothing would have said so |
  | `unknown` | the registry could not be reached; not an error, but not a clean bill of health either |

  A brand-new package is the sharp edge `MISSING` catches: its first version
  appears in both files, so it is skipped forever and never reaches pub.dev.
  `revali_redis` works around this by starting its pubspec at `0.0.0`, which
  works and only works if whoever adds the package remembers.
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
- `prep_for_publish.dart` runs `pub publish --force`, which cannot be undone.
  It prints the plan first, and **refuses outright when no terminal is
  attached** rather than attempting a prompt it cannot complete. `--yes`
  publishes without asking.

  **`sip run publish` passes `--yes`** (`scripts.yaml`), so the confirmation
  step is gone from the normal path — the two test runs ahead of it are what
  stands in for it. That was added on 08.15.26 so the release could be run
  from an agent session, where stdout is captured and the terminal check can
  never pass. It is a deliberate trade and worth re-reading before a round
  with a major in it: the plan is still printed, but nothing waits for a human
  to agree with it. Drop the flag to get the prompt back.

  Invoking `prep_for_publish.dart` directly still refuses without a terminal.
  Piping its output to a file or a log is enough to make `stdout` not a
  terminal, at which point it declines and explains why.
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

# Cadence

Offline-first blood pressure diary for Android. Session-based readings following the 7-2-2 home monitoring protocol. Flutter, no accounts, no ads, your data stays yours.

Cadence is a blood pressure diary for people who measure at home and want the numbers to mean something.

Most BP apps treat every reading as an isolated event. Cadence treats measurement as a session — the rest, the two readings a minute apart, the morning and the evening — because that's how home monitoring is meant to work. It follows the 7-2-2 protocol recommended in the ESH/AHA guidelines, and shows you not just your numbers but whether you actually collected enough of them to draw a conclusion.

No accounts. No ads. No cloud. Your readings live in a SQLite database on your device, and you can export all of them at any time in a format you can read.

Cadence is a diary, not a medical device. It records what your monitor tells you and does the arithmetic. It does not measure blood pressure, and it does not diagnose anything — that conversation belongs with your doctor.

## Status

Early scaffolding. There are no features yet: the repository holds the project skeleton only — the three-layer architecture (`lib/domain`, `lib/data`, `lib/ui`), strict static analysis with enforced import boundaries, ARB localisation, and a pre-commit gate. See [`CLAUDE.md`](CLAUDE.md) for the architecture and the constraints that shape it.

## Development

Requires the Flutter SDK (stable) and [lefthook](https://lefthook.dev).

On a fresh clone:

```sh
flutter pub get   # fetch dependencies and generate localisations
lefthook install  # wire the pre-commit gate into .git/hooks (once)
```

Run the full gate manually at any time:

```sh
lefthook run pre-commit
```

The gate runs `dart format`, `flutter analyze`, `dart analyze` (which enforces the layered import boundaries), and `flutter test`.

## Licence

Apache 2.0 — see [`LICENSE`](LICENSE).

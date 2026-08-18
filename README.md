# SignalGate Demo

**Open the app and the first thing on screen is `INCONCLUSIVE` — on a build hiding a genuine 12-point quality regression.**

That is not a bug in the demo. It is the demo. At 120 samples per arm there is not enough evidence to prove the regression *or* clear the build, and the honest answer is to say so. Drag the sample-size slider and watch the verdict resolve into `BLOCK` as the interval tightens past the margin — it does, and stays there, from about n=1,200 onward.

Then switch to **Equivalent build** and drag back down. The same slider that turned a regression into a block turns a perfectly good build into `INCONCLUSIVE` too. Small samples do not produce wrong answers. They produce *no* answers, and a two-state gate is forced to launder that into a pass.

This app is a thin shell over **[signal-gate-kit](https://github.com/rajatslakhina/signal-gate-kit)**, consumed as a remote Swift Package.

---

## Why this matters

A deterministic test suite promises that green means correct. Once "the test" is an inference call, green only means *the sample you happened to draw did not contradict you.* Every dashboard in CI is built to display the first claim.

The six scenarios in the picker are the cases that decide whether a quality gate is any good, and a point-estimate gate gets all six wrong:

| Scenario | What's really happening | What a naive gate does |
|---|---|---|
| **Equivalent build** | Candidate matches baseline | Blocks whenever noise lands the wrong way |
| **2-point wobble** | Drop is inside the declared margin | Blocks — it has no concept of "meaningfully worse" |
| **Real regression** | 12 points worse | Passes at small n, because it has no power |
| **One slice collapsed** | Aggregate flat, `de-DE` down 30 points | Passes — it watches the average |
| **Judge drifted lenient** | Judge is +8 points vs. its human golden set | Passes, confidently, forever |
| **Judge offline** | No judge verdicts at all | Passes — nothing failed, so nothing is wrong |

The last two are the ones worth staring at. Both fail **before** any pass-rate arithmetic runs, because an uncalibrated or missing judge does not make the numbers noisy — it makes them meaningless, and a tidy confidence interval computed over meaningless inputs is exactly how a broken eval pipeline produces a confident green.

"Judge drifted lenient" is deliberately configured to have *good* agreement (Cohen's κ ≈ 0.75, well above the 0.60 floor). A judge that disagrees loudly is easy to catch. The dangerous one agrees most of the time and is systematically generous at the margin — only the bias check sees it.

Two behaviours in the app are worth knowing are intentional rather than broken:

- **"2-point wobble" never blocks, at any slider position.** It is inside the margin, so it is not a regression, and the gate is a non-inferiority test rather than an equality test. Swept across all 499 reachable sample sizes in the library's test suite.
- **Sequential mode never reaches `PASS` in this slider's range.** An anytime-valid interval costs roughly 2.4× the width of a fixed-sample one at n=40, and about 4× at the boundary. That is what buying the right to peek after every sample costs, and the app says so rather than letting you drag forever waiting for a green that cannot appear.

---

## What's on screen

- **Verdict banner** — `PASS` / `BLOCK` / `INCONCLUSIVE`, with the reason and, where sample size is the binding constraint, how many more per arm would resolve it.
- **Interval strip** — the confidence interval on `candidate − baseline`, drawn against the non-inferiority margin. The three-state logic is geometric: wholly right of the margin is pass, wholly left is block, straddling it is inconclusive. The axis auto-scales, so a wide small-sample interval is never silently clipped into looking decisive.
- **Why** — the rationale lines the gate would write into a CI log, including the union bound on its own false-block rate. A gate that blocks without explaining gets disabled within a week.
- **Judge** — κ and leniency bias, or the specific reason the judge is not trusted.
- **Slices** — per-slice results with Benjamini–Hochberg adjusted p-values, and a line comparing what the *uncorrected* gate would have flagged. With 6 slices at α=0.05, uncorrected false-alarms 26% of the time; at 12 slices it is 46%.

---

## Screenshots

**There are none, and that is a deliberate omission rather than an oversight.**

This project was produced by an unattended scheduled run, which cannot obtain computer-use access. The request was made three times, once narrowed to the Simulator alone, and returned verbatim:

> Computer-use access to "Simulator" can't be approved during a scheduled run. To grant it, send a message in this conversation (the approval card will appear), or add the app to the scheduled task's settings. (Retrying returns this same result.)

So: **this app has not been launched on a Simulator.** No screenshot of it exists, and none has been mocked up or described as if it did. What *is* verified is stated below, and "compiles for a Simulator" is a separate and weaker claim than "ran on a Simulator."

---

## How to run it

```bash
git clone https://github.com/rajatslakhina/signal-gate-kit-demo-app.git
cd signal-gate-kit-demo-app
open Demo.xcodeproj
```

Xcode resolves `signal-gate-kit` from GitHub on first open. Then select the **Demo** scheme, pick any iOS Simulator, and Build & Run. No signing team or local checkout is needed.

The dependency is an `XCRemoteSwiftPackageReference` with `upToNextMajorVersion` from `1.0.0` — so a fresh clone resolves the newest 1.x release rather than whatever `main` happens to be that day. Note what that does and does not guarantee: it excludes unreleased `main`, but it does not freeze the exact version, so a later 1.x release will be picked up. Pin `exactVersion` or commit a `Package.resolved` if you need byte-identical resolution.

Requires Xcode 16+ and iOS 17+.

---

## Verification

See the [Actions tab](https://github.com/rajatslakhina/signal-gate-kit-demo-app/actions) for what actually ran. One job on `macos-15` with Xcode 16, in two meaningful steps — both of which have run and passed:

1. **`xcodebuild -resolvePackageDependencies`** — proves the remote package genuinely resolves from GitHub. This is the step that fails if the tag is wrong, the repo is private, or the dependency is secretly a stale local path.
2. **`xcodebuild build -destination 'generic/platform=iOS Simulator'`** — compiles the app against the resolved package for iOS.

`generic/platform=iOS Simulator` rather than a named device is intentional. Pinning to something like `name=iPhone 16,OS=latest` ties the job to whichever simulator *runtimes* are installed on that day's runner image, which is not guaranteed — a compile-only check needs no device to exist.

This CI job is the cheapest honest substitute for a human opening the project, and on a run where the Simulator step is blocked it is the only real evidence the project works at all. It is not a substitute for launching the app, and it does not exercise a single line of UI behaviour.

The library itself carries **108 XCTest tests**, green on both Linux and macOS, including sweeps across all 499 reachable slider positions that pin the scenario behaviour this app depends on — see [signal-gate-kit](https://github.com/rajatslakhina/signal-gate-kit).

## License

MIT — see [LICENSE](LICENSE).

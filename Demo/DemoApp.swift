import SwiftUI
import SignalGate
import SignalGateUI

@main
struct DemoApp: App {

    /// The gate policy lives in the app, not the library.
    ///
    /// This is the point of the split. A non-inferiority margin is a product
    /// decision — "how much quality loss is acceptable before we stop a merge?"
    /// — and there is no defensible library default for it. Baking one in would
    /// let every team inherit a number nobody chose. So `SignalGate` requires
    /// the policy as a parameter, and this app is the thing that answers for it.
    ///
    /// The values below are the ones a real team would have to argue about:
    /// a 3-point acceptable drop, 95% confidence, FDR held at 5% across slices,
    /// and sample-size advice computed against a 5-point detectable effect at
    /// 80% power.
    private let policy = GatePolicy(
        nonInferiorityMargin: 0.03,
        confidence: 0.95,
        sliceFalseDiscoveryRate: 0.05,
        minimumDetectableEffect: 0.05,
        power: 0.80,
        mode: .fixedSample,
        judgePolicy: JudgeCalibrationPolicy(
            minimumKappa: 0.60,
            maximumAbsoluteBias: 0.05,
            minimumGoldenSetSize: 50
        )
    )

    var body: some Scene {
        WindowGroup {
            // Opens on a build that hides a genuine 12-point regression, at a
            // sample size too small to prove it. The first thing on screen is
            // therefore INCONCLUSIVE — which is the argument the whole package
            // is making, visible before the user touches anything.
            GateConsoleView(
                policy: policy,
                initialScenario: .realRegression,
                initialSamplesPerArm: 120
            )
        }
    }
}

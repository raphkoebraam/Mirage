import MirageCLI
import Synchronization

/// Test double for `UserInterface`: records everything, answers prompts from
/// pre-seeded scripts.
final class RecordingUI: UserInterface, Sendable {
    enum Event: Equatable {
        case success(String)
        case info(String)
        case warning(String)
        case error(String)
        case output(String)
        case table(headers: [String], rows: [[String]])
        case progress(String)
        case confirm(String)
        case choose(String)
    }

    private struct State {
        var events: [Event] = []
        var confirmAnswers: [Bool] = []
        var chooseAnswers: [String?] = []
    }

    private let state = Mutex(State())
    let isInteractive: Bool

    init(isInteractive: Bool = true) {
        self.isInteractive = isInteractive
    }

    var events: [Event] { state.withLock(\.events) }

    /// All raw `output` text joined by newlines, for content assertions.
    var outputText: String {
        events.compactMap { if case let .output(text) = $0 { text } else { nil } }
            .joined(separator: "\n")
    }

    var successMessages: [String] {
        events.compactMap { if case let .success(message) = $0 { message } else { nil } }
    }

    var errorMessages: [String] {
        events.compactMap { if case let .error(message) = $0 { message } else { nil } }
    }

    var tables: [(headers: [String], rows: [[String]])] {
        events.compactMap { if case let .table(headers, rows) = $0 { (headers, rows) } else { nil } }
    }

    func answerConfirm(_ answer: Bool) {
        state.withLock { $0.confirmAnswers.append(answer) }
    }

    func answerChoose(_ answer: String?) {
        state.withLock { $0.chooseAnswers.append(answer) }
    }

    func success(_ message: String) { record(.success(message)) }
    func info(_ message: String) { record(.info(message)) }
    func warning(_ message: String) { record(.warning(message)) }
    func error(_ message: String) { record(.error(message)) }
    func output(_ text: String) { record(.output(text)) }

    func table(headers: [String], rows: [[String]]) {
        record(.table(headers: headers, rows: rows))
    }

    func progress(
        _ message: String,
        successMessage _: String?,
        task: @escaping @Sendable () async throws -> Void
    ) async throws {
        record(.progress(message))
        try await task()
    }

    func confirm(_ question: String, defaultAnswer: Bool) -> Bool {
        record(.confirm(question))
        return state.withLock {
            $0.confirmAnswers.isEmpty ? defaultAnswer : $0.confirmAnswers.removeFirst()
        }
    }

    func choose(_ question: String, options _: [String]) -> String? {
        record(.choose(question))
        return state.withLock {
            $0.chooseAnswers.isEmpty ? nil : $0.chooseAnswers.removeFirst()
        }
    }

    private func record(_ event: Event) {
        state.withLock { $0.events.append(event) }
    }
}

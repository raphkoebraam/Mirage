import Noora

/// Production `UserInterface` backed by Noora (ADR 0001). The only file in
/// the codebase that imports Noora.
public struct NooraUI: UserInterface {
    private let noora: Noora

    public let isInteractive: Bool

    public init() {
        noora = Noora()
        isInteractive = Terminal.isInteractive()
    }

    public func success(_ message: String) {
        noora.success(.alert("\(message)"))
    }

    public func info(_ message: String) {
        noora.info(.alert("\(message)"))
    }

    public func warning(_ message: String) {
        noora.warning(.alert("\(message)"))
    }

    public func error(_ message: String) {
        noora.error(.alert("\(message)"))
    }

    public func output(_ text: String) {
        print(text)
    }

    public func table(headers: [String], rows: [[String]]) {
        noora.table(headers: headers, rows: rows)
    }

    public func progress(
        _ message: String,
        successMessage: String?,
        task: @escaping @Sendable () async throws -> Void
    ) async throws {
        try await noora.progressStep(
            message: message,
            successMessage: successMessage,
            errorMessage: nil,
            showSpinner: true
        ) { _ in
            try await task()
        }
    }

    public func confirm(_ question: String, defaultAnswer: Bool) -> Bool {
        guard isInteractive else { return defaultAnswer }
        return noora.yesOrNoChoicePrompt(
            title: nil,
            question: "\(question)",
            defaultAnswer: defaultAnswer,
            description: nil,
            collapseOnSelection: true
        )
    }

    public func choose(_ question: String, options: [String]) -> String? {
        guard isInteractive, !options.isEmpty else { return nil }
        return noora.singleChoicePrompt(
            title: nil,
            question: "\(question)",
            options: options,
            description: nil,
            collapseOnSelection: true,
            filterMode: .enabled,
            autoselectSingleChoice: true
        )
    }
}

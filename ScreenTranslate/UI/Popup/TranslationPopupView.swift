import SwiftUI

struct TranslationPopupView: View {
    let state: TranslationCoordinator.State
    let onCopy: (String) -> Void
    let onClose: () -> Void
    let onToggleOriginal: (Bool) -> Void
    let autoCopied: Bool
    var onOpenSettings: (() -> Void)? = nil

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var fontSize: CGFloat { AppSettings.shared.popupFontSize }
    private var popupFont: Font { FontManager.shared.swiftUIFont(size: fontSize) }
    private var popupFontSmall: Font { FontManager.shared.swiftUIFont(size: fontSize - 2) }

    @State private var didCopy = false
    @State private var showingOriginal = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                switch state {
                case .idle:
                    EmptyView()

                case .recognizing:
                    loadingView(message: L10n.recognizing)

                case .translating:
                    loadingView(message: L10n.translating)

                case .completed(let result):
                    completedView(result: result)

                case .failed(let message):
                    errorView(message: message)
                }

                HStack {
                    if case .completed = state {
                        Toggle(L10n.showOriginal, isOn: $showingOriginal)
                            .toggleStyle(.checkbox)
                            .onChange(of: showingOriginal) { _, newValue in
                                onToggleOriginal(newValue)
                            }
                    }

                    Spacer()

                    if case .completed(let result) = state {
                        Button(didCopy ? L10n.copied : L10n.copy) {
                            onCopy(result.translatedText)
                            didCopy = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                didCopy = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(didCopy ? .green : .accentColor)
                        .keyboardShortcut("c", modifiers: .command)
                        .onChange(of: autoCopied) { _, newValue in
                            if newValue {
                                didCopy = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    didCopy = false
                                }
                            }
                        }
                    }

                    Button(L10n.close) {
                        onClose()
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.cancelAction)
                }
            }
            .padding(16)

            // 리사이즈 그립 아이콘 (completed/failed에서만 표시)
            if isResizableState {
                resizeGripIcon
            }
        }
        .frame(minWidth: 280, maxWidth: .infinity)
        .background(reduceTransparency ? AnyShapeStyle(Color(nsColor: .windowBackgroundColor)) : AnyShapeStyle(.regularMaterial))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 12, y: 4)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: showingOriginal)
    }

    // MARK: - Resize Grip

    private var isResizableState: Bool {
        switch state {
        case .completed, .failed: return true
        default: return false
        }
    }

    private var resizeGripIcon: some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.system(size: 7))
            .foregroundStyle(.tertiary)
            .padding(3)
    }

    // MARK: - Subviews

    private func loadingView(message: String) -> some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text(message)
                .font(popupFont)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func completedView(result: TranslationCoordinator.TranslationResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if result.lowConfidence {
                Label(L10n.lowConfidence, systemImage: "exclamationmark.triangle")
                    .font(popupFontSmall)
                    .foregroundStyle(.orange)
            }

            // 병음 (원문이 중국어일 때, 설정 활성화 시 번역문 위에 표시)
            if let pinyinText = pinyinIfApplicable(for: result) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.pinyin)
                        .font(popupFontSmall)
                        .foregroundStyle(.tertiary)
                    Text(pinyinText)
                        .font(popupFontSmall)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // 번역문 — 짧은 텍스트는 자연 크기, 긴 텍스트만 스크롤
            ScrollView {
                Text(result.translatedText)
                    .font(popupFont)
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                    .accessibilityLabel(L10n.translatedText)
                    .accessibilityValue(result.translatedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity)

            // 원문 (토글 시)
            if showingOriginal {
                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(L10n.originalText)
                            .font(popupFontSmall)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let lang = result.sourceLanguage {
                            Text(Locale.current.localizedString(
                                forIdentifier: lang.minimalIdentifier) ?? "")
                                .font(popupFontSmall)
                                .foregroundStyle(.secondary)
                        }
                    }

                    ScrollView {
                        Text(result.sourceText)
                            .font(popupFont)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: .infinity)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    /// 원문이 중국어이고 설정이 켜져 있으며 병음이 원문과 다를 때만 병음 문자열을 반환한다.
    /// auto-detect 실패(sourceLanguage == nil) 시에는 의도적으로 표시하지 않는다.
    private func pinyinIfApplicable(
        for result: TranslationCoordinator.TranslationResult
    ) -> String? {
        guard AppSettings.shared.showPinyinForChinese,
              PinyinConverter.isChinese(result.sourceLanguage),
              let py = PinyinConverter.pinyin(for: result.sourceText),
              py != result.sourceText
        else { return nil }
        return py
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(message)
                .font(popupFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if message == L10n.autoDetectFailedMessage, let onOpenSettings {
                Button(L10n.openSettings) {
                    onOpenSettings()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

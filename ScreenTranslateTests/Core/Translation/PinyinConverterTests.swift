import Foundation
import Testing
@testable import ScreenTranslate

struct PinyinConverterTests {

    // MARK: - pinyin(for:)

    @Test("simplified Chinese is converted to pinyin with tone marks")
    func simplified() {
        let result = PinyinConverter.pinyin(for: "你好世界")
        #expect(result != nil)
        // 정확한 음운 확인 — kCFStringTransformMandarinLatin은 성조 부호를 포함한다.
        #expect(result == "nǐ hǎo shì jiè")
    }

    @Test("traditional Chinese is converted to pinyin")
    func traditional() {
        let result = PinyinConverter.pinyin(for: "歡迎光臨")
        #expect(result != nil)
        #expect(result == "huān yíng guāng lín")
    }

    @Test("mixed Han + Latin keeps Latin segments and converts Han")
    func mixed() {
        let result = PinyinConverter.pinyin(for: "Hello 世界")
        #expect(result != nil)
        #expect(result?.contains("Hello") == true)
        #expect(result?.contains("shì jiè") == true)
    }

    @Test("empty string returns nil")
    func empty() {
        #expect(PinyinConverter.pinyin(for: "") == nil)
    }

    @Test("non-Chinese Latin text passes through")
    func nonChineseLatin() {
        // Latin 입력은 그대로 반환되어야 한다 (변환 대상이 아님).
        #expect(PinyinConverter.pinyin(for: "hello") == "hello")
    }

    @Test("collapses multiple spaces produced by punctuation")
    func collapsesSpaces() {
        // 한자 사이에 공백/구두점이 있으면 변환 후 공백이 늘어날 수 있다.
        let result = PinyinConverter.pinyin(for: "你好 ， 世界")
        #expect(result != nil)
        #expect(result?.contains("  ") == false)  // 다중 공백 없음
    }

    // MARK: - isChinese(_:)

    @Test("isChinese identifies zh, zh-Hans, zh-Hant", arguments: [
        ("zh", true),
        ("zh-Hans", true),
        ("zh-Hant", true),
        ("zh-CN", true),
        ("zh-TW", true),
        ("ko", false),
        ("ja", false),
        ("en", false),
    ])
    func isChineseLanguage(code: String, expected: Bool) {
        #expect(PinyinConverter.isChinese(Locale.Language(identifier: code)) == expected)
    }

    @Test("isChinese with nil language returns false")
    func isChineseNil() {
        #expect(PinyinConverter.isChinese(nil) == false)
    }

    @Test("isChinese(languageCode:) string variant", arguments: [
        (Optional<String>.some("zh-Hans"), true),
        (Optional<String>.some("zh-Hant"), true),
        (Optional<String>.some("ko"), false),
        (Optional<String>.none, false),
    ])
    func isChineseString(code: String?, expected: Bool) {
        #expect(PinyinConverter.isChinese(languageCode: code) == expected)
    }
}

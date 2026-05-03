import Foundation

/// 한자(중국어 간체/번체) → 한어병음(성조 부호 포함) 변환기.
/// `CFStringTransform`의 `kCFStringTransformMandarinLatin` 변환을 사용한다.
enum PinyinConverter {
    /// 입력 텍스트의 한자를 한어병음(성조 부호 포함)으로 변환한다.
    /// 예: "你好" → "nǐ hǎo", "歡迎光臨" → "huān yíng guāng lín"
    /// 변환 실패 또는 결과가 빈 문자열이면 nil을 반환한다.
    static func pinyin(for text: String) -> String? {
        guard !text.isEmpty else { return nil }

        let mutable = NSMutableString(string: text)
        guard CFStringTransform(mutable, nil, kCFStringTransformMandarinLatin, false)
        else { return nil }

        // 구두점 처리 후 발생할 수 있는 다중 공백을 단일 공백으로 정리.
        let collapsed = (mutable as String)
            .replacingOccurrences(of: " +", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return collapsed.isEmpty ? nil : collapsed
    }

    /// 주어진 언어가 만다린(중국어 간체/번체)인지 판별한다.
    /// `Locale.Language("zh-Hans").languageCode?.identifier == "zh"` 이므로
    /// 단일 비교로 zh, zh-Hans, zh-Hant를 모두 처리한다.
    static func isChinese(_ language: Locale.Language?) -> Bool {
        language?.languageCode?.identifier == "zh"
    }

    /// String 형태의 언어 코드용 편의 메서드 (히스토리 등에서 사용).
    static func isChinese(languageCode: String?) -> Bool {
        guard let code = languageCode else { return false }
        return Locale.Language(identifier: code).languageCode?.identifier == "zh"
    }
}

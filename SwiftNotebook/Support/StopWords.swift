import Foundation

/// A small, deliberately conservative stopword list for the frequent-words cloud — filtering out
/// common function words so the cloud surfaces actual topics rather than "that"/"with"/"were".
enum StopWords {
    static let english: Set<String> = [
        "the", "and", "for", "are", "but", "not", "you", "all", "can", "her", "was", "one", "our",
        "out", "day", "get", "has", "him", "his", "how", "man", "new", "now", "old", "see", "two",
        "way", "who", "did", "its", "let", "put", "say", "she", "too", "use", "this", "that",
        "with", "have", "from", "were", "been", "your", "just", "into", "some", "than", "them",
        "then", "they", "will", "what", "when", "where", "which", "would", "there", "their",
        "about", "after", "again", "before", "could", "every", "first", "found", "great", "little",
        "might", "much", "must", "never", "other", "over", "same", "should", "still", "such",
        "these", "thing", "think", "those", "through", "today", "under", "until", "very", "while",
        "also", "back", "because", "being", "does", "doing", "down", "each", "even", "here", "made",
        "make", "more", "most", "myself", "off", "only", "once", "own",
    ]
}

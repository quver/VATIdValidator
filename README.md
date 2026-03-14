# VATIdValidator

[![CI](https://github.com/quver/VATIdValidator/actions/workflows/ci.yml/badge.svg)](https://github.com/quver/VATIdValidator/actions/workflows/ci.yml)
[![GitHub license](https://img.shields.io/github/license/quver/VATIdValidator.svg)](https://github.com/quver/VATIdValidator/blob/main/LICENSE)
[![Swift Package Manager compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fquver%2FVATIdValidator%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/quver/VATIdValidator)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fquver%2FVATIdValidator%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/quver/VATIdValidator)

Polish VAT Identification (NIP) number validator.

## Requirements

- iOS 13+ / macOS 10.15+ / tvOS 13+ / watchOS 7+
- Swift 6.1+
- Xcode 16.4+

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/quver/VATIdValidator.git", from: "2.0.0")
]
```

Or add it directly in Xcode via **File → Add Package Dependencies**.

## Usage

### Validation with error handling

```swift
let validator = VATIdValidator(5260250274)
do {
    try validator.validate()
    // Valid NIP
} catch VATIdValidator.ValidationError.incorrectLength {
    // NIP must have exactly 10 digits
} catch VATIdValidator.ValidationError.invalidDigit {
    // NIP contains non-digit characters
} catch VATIdValidator.ValidationError.checkSumNotMatch {
    // Checksum verification failed
}
```

### Bool extensions

```swift
if 5260250274.isValidVATId { }
if "5260250274".isValidVATId { }
if 5260250274.0.isValidVATId { }
```

### Supported input types

```swift
VATIdValidator([5, 2, 6, 0, 2, 5, 0, 2, 7, 4])  // [Int]
VATIdValidator(5260250274)                         // BinaryInteger
VATIdValidator(5260250274.0)                       // Double
VATIdValidator("5260250274")                       // String
```

## Documentation

Full API documentation is available at [quver.github.io/VATIdValidator](https://quver.github.io/VATIdValidator/documentation/vatidvalidator/).

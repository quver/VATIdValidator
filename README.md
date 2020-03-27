# VATIdValidator

![CI](https://github.com/quver/VATIdValidator/workflows/CI/badge.svg)
[![GitHub license](https://img.shields.io/github/license/quver/VATIdValidator.svg)]()
[![Swift Package Manager compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)
[![codebeat badge](https://codebeat.co/badges/a96882e8-2953-4453-8734-cbc6edb9c16c)](https://codebeat.co/projects/github-com-quver-vatidvalidator-master)
[![codecov](https://codecov.io/gh/quver/VATIdValidator/branch/master/graph/badge.svg)](https://codecov.io/gh/quver/VATIdValidator)
[![Readme Score](http://readme-score-api.herokuapp.com/score.svg?url=https://github.com/quver/vatidvalidator)](http://clayallsopp.github.io/readme-score?url=https://github.com/quver/vatidvalidator)
[![Documentation](https://quver.github.io/VATIdValidator/badge.svg)](https://quver.github.io/VATIdValidator/index.html)

Polish VAT Identification (NIP) number validator.

## API
### Initialisation

```swift
VATIdValidator([Int])
VATIdValidator(BinaryInteger)
VATIdValidator(Double)
VATIdValidator(StringLiteralType)
```
### Validation
```swift
let validator = VATIdValidator(5260250274)
try validator.validate()
```
### Extensions
- BinaryInteger
- Double
- StringLiteralType

```swift
var isValidVATId: Bool { get }
```
#### Example

```swift
if 5260250274.isValidVATId {
	// Do the magic 🎊
}

if "5260250274".isValidVATId {
	// Other magic 🎉
}
```

## Using
### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is dependency manager built by Apple and integrated with Xcode and into `swift` compiler.

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/quver/VATIdValidator.git", .upToNextMajor(from: "1.0.0"))
]
```

### Cocoapods

The [Cocoapods](https://cocoapods.org/) is a dependency manager for Swift and Objective-C. Supports iOS, watchOS, tvOS and macOS.

Add to your `Podfile`:

```
pod 'VATIdValidator'
```

Than run:

```
pod install
```
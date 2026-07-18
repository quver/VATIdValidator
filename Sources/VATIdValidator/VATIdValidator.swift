public struct VATIdValidator: Sendable {

    /**
     ## Possible validation errors.

      - `incorrectLength` - The VAT identifier should have 10 digits.
      - `invalidDigit` - Each element must be a single digit (0–9).
      - `checkSumNotMatch` - Checksum should be equal 10th digit of the VAT Identifier.
     */
    public enum ValidationError: Error, Sendable {

        /// The VAT Identifier should have 10 digits.
        case incorrectLength

        /// Each element must be a single digit (0–9).
        case invalidDigit

        /// Checksum should be equal 10th digit of the VAT ID.
        case checkSumNotMatch

    }

    private enum Constants {
        static let vatIdLength = 10
        static let checkSumWeights = [6, 5, 7, 2, 3, 4, 5, 6, 7]
    }

    private let digits: [Int]

    /**
     Common constructor.
     - Parameter vatId: The VAT identifier as array of integers.
     */
    public init(_ vatId: [Int]) {
        self.digits = vatId
    }

    /**
     Common constructor.
     - Parameter vatId: The VAT identifier as any integer.

     Negative values are not a valid representation of a VAT identifier and are treated as invalid.
     */
    public init<T: BinaryInteger>(_ vatId: T) {
        guard vatId >= 0 else {
            self.init([])
            return
        }
        self.init(String(vatId))
    }

    /**
     Common constructor. Converts double to integer, discarding any fractional part
     (truncated toward zero) — `5260250274.7` validates the same as `5260250274`.
     - Parameter vatId: The VAT identifier as double.

     Non-finite or out-of-range values (e.g. `.nan`, `.infinity`) are treated as invalid instead of crashing.
     */
    public init(_ vatId: Double) {
        guard let intValue = Int(exactly: vatId.rounded(.towardZero)) else {
            self.init([])
            return
        }
        self.init(intValue)
    }

    /**
     Common constructor.
     - Parameter vatId: The VAT identifier as string.

     Non-digit characters (dashes, spaces, letters — including a leading `-`) are ignored
     as formatting separators; validation runs on the remaining digits.
     */
    public init(_ vatId: String) {
        self.digits = vatId.compactMap { $0.wholeNumberValue }
    }

    /**
     Validates VAT identifier.
     - Throws:
        - `ValidationError.incorrectLength` The VAT Identifier should have 10 digits.
        - `ValidationError.invalidDigit` Each element must be a single digit (0–9).
        - `ValidationError.checkSumNotMatch` Checksum should be equal 10th digit of the VAT Identifier.
     */
    public func validate() throws(ValidationError) {
        // The VAT identifier should have 10 digits.
        guard digits.count == Constants.vatIdLength else { throw ValidationError.incorrectLength }

        // Each digit must be in range 0–9.
        guard digits.allSatisfy({ (0...9).contains($0) }) else { throw ValidationError.invalidDigit }

        // Checksum should be equal 10th digit of the VAT identifier.
        guard checkSum() == digits[9] else { throw ValidationError.checkSumNotMatch }
    }

    private func checkSum() -> Int {
        zip(Constants.checkSumWeights, digits)
            .map { weight, digit in weight * digit }
            .reduce(0, +) % 11
    }

}

public extension BinaryInteger {

    /**
     Is valid VAT identifier.
     */
    var isValidVATId: Bool { (try? VATIdValidator(self).validate()) != nil }

}

public extension String {

    /**
    Is valid VAT identifier.
    */
    var isValidVATId: Bool { (try? VATIdValidator(self).validate()) != nil }

}

public extension Double {

    /**
    Is valid VAT identifier.
    */
    var isValidVATId: Bool { (try? VATIdValidator(self).validate()) != nil }

}

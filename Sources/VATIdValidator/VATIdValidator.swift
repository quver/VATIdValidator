public struct VATIdValidator {

    /**
     ## Possible validation errors.

      - `incorrectLength` - The VAT identifier should have 10 digits.
      - `invalidDigit` - Each element must be a single digit (0–9).
      - `checkSumNotMatch` - Checksum should be equal 10th digit of the VAT Identifier.
     */
    public enum ValidationError: Error {

        /// The VAT Identifier should have 10 digits.
        case incorrectLength

        /// Each element must be a single digit (0–9).
        case invalidDigit

        /// Checksum should be equal 10th digit of the VAT ID.
        case checkSumNotMatch

    }

    private let digits: [Int]
    private let vatIdLength = 10

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
     */
    public init<T: BinaryInteger>(_ vatId: T) {
        self.init(String(vatId))
    }

    /**
     Common constructor. Converts double to integer.
     - Parameter vatId: The VAT identifier as double.
     */
    public init(_ vatId: Double) {
        self.init(Int(vatId))
    }

    /**
     Common constructor.
     - Parameter vatId: The VAT identifier as string.
     */
    public init(_ vatId: String) {
        self.digits = vatId.compactMap { $0.wholeNumberValue }
    }

    /**
     Validates VAT identifer.
     - Throws:
        - `ValidationError.incorrectLength` The VAT Identifier should have 10 digits.
        - `ValidationError.checkSumNotMatch` Checksum should be equal 10th digit of the VAT Identifier.
     */
    public func validate() throws {
        // The VAT identifier should have 10 digits.
        guard digits.count == vatIdLength else { throw ValidationError.incorrectLength }

        // Each digit must be in range 0–9.
        guard digits.allSatisfy({ (0...9).contains($0) }) else { throw ValidationError.invalidDigit }

        // Checksum should be equal 10th digit of the VAT identifier.
        guard checkSum() == digits[9] else { throw ValidationError.checkSumNotMatch }
    }

    private func checkSum() -> Int {
        return (6 * digits[0] +
            5 * digits[1] +
            7 * digits[2] +
            2 * digits[3] +
            3 * digits[4] +
            4 * digits[5] +
            5 * digits[6] +
            6 * digits[7] +
            7 * digits[8]) % 11
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

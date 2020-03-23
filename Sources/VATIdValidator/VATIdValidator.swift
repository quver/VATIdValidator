public struct VATIdValidator {
    
    /**
     ## Possible validation errors.
     
      - `incorrectLength` - The VAT identifier should have 10 digits.
      - `checkSumNotMatch` - Checksum should be equal 10th digit of the VAT Identifier.
     */
    public enum ValidationError: Error {

        /// The VAT Identifier should have 10 digits.
        case incorrectLength
        
        /// Checksum should be equal 10th digit of the VAT ID.
        case checkSumNotMatch
        
    }
    
    let vatId: [Int?]
    private let filteredVATId: [Int]
    private let vatIdLength = 10
    
    /**
     Common constructor.
     - Parameter vatId: The VAT identifier as array of integers.
     */
    public init(_ vatId: [Int]) {
        self.vatId = vatId
        self.filteredVATId = vatId.compactMap { $0 }
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
    public init(_ vatId: StringLiteralType) {
        self.vatId = vatId.map { Int(String($0)) }
        filteredVATId = self.vatId.compactMap { $0 }
    }

    /**
     Validates VAT identifer.
     - Throws:
        - `ValidationError.incorrectLength` The VAT Identifier should have 10 digits.
        - `ValidationError.checkSumNotMatch` Checksum should be equal 10th digit of the VAT Identifier.
     */
    public func validate() throws {
        // The VAT identifier should have 10 digits.
        guard vatId.count == vatIdLength
            && filteredVATId.count == vatIdLength else { throw ValidationError.incorrectLength }
        
        // Checksum should be equal 10th digit of the VAT identifier.
        guard checkSum() == vatId[9] else { throw ValidationError.checkSumNotMatch }
    }
    
    func checkSum() -> Int? {
        guard vatId.count == vatIdLength && filteredVATId.count == vatIdLength else { return nil }
        
        return (6 * filteredVATId[0] +
            5 * filteredVATId[1] +
            7 * filteredVATId[2] +
            2 * filteredVATId[3] +
            3 * filteredVATId[4] +
            4 * filteredVATId[5] +
            5 * filteredVATId[6] +
            6 * filteredVATId[7] +
            7 * filteredVATId[8]) % 11
    }
    
}

extension BinaryInteger {
    
    /**
     Is valid VAT identifier.
     */
    public var isValidVATId: Bool { (try? VATIdValidator(self).validate()) != nil }
    
}

extension StringLiteralType {
    
    /**
    Is valid VAT identifier.
    */
    public var isValidVATId: Bool { (try? VATIdValidator(self).validate()) != nil }
    
}

extension Double {
    
    /**
    Is valid VAT identifier.
    */
    public var isValidVATId: Bool { (try? VATIdValidator(self).validate()) != nil }
    
}

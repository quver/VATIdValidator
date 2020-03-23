import XCTest
@testable import VATIdValidator

final class VATIdValidatorTests: XCTestCase {
    
    typealias ValidationError = VATIdValidator.ValidationError
    
    static var allTests = [
        ("testInitWithIntArray", testInitWithIntArray),
        ("testInitWithInt", testInitWithInt),
        ("testInitWithInt64", testInitWithInt64),
        ("testInitWithUInt", testInitWithUInt),
        ("testInitWithUInt64", testInitWithUInt64),
        ("testInitWithDouble", testInitWithDouble),
        ("testInitWithString", testInitWithString),
        ("testChecksumMinistryOfFinanceVATId", testChecksumMinistryOfFinanceVATId),
        ("testChecksumChancelleryOfThePrimeMinisterVATId", testChecksumChancelleryOfThePrimeMinisterVATId),
        ("testChecksumWithInvalidVATId", testChecksumWithInvalidVATId),
        ("testValidationMinistryOfFinanceVATId", testValidationMinistryOfFinanceVATId),
        ("testValidationChancelleryOfThePrimeMinisterVATId", testValidationChancelleryOfThePrimeMinisterVATId),
        ("testValidationWithIncorectLength", testValidationWithIncorectLength),
        ("testValidationWithChceckSumNotMatch", testValidationWithChceckSumNotMatch),
        ("testBinaryIntegerExtensionIsValidTrue", testBinaryIntegerExtensionIsValidTrue),
        ("testBinaryIntegerExtensionIsValidFalse", testBinaryIntegerExtensionIsValidFalse),
        ("testStringLiteralTypeExtensionIsValidTrue", testStringLiteralTypeExtensionIsValidTrue),
        ("testStringLiteralTypeExtensionIsValidFalse", testStringLiteralTypeExtensionIsValidFalse),
        ("testDoubleExtensionIsValidTrue", testDoubleExtensionIsValidTrue),
        ("testDoubleExtensionIsValidFalse", testDoubleExtensionIsValidFalse)
    ]
    
    // VAT ID numbers:
    //
    // Valid
    // - 5260250274
    // - 5261645000
    //
    // Invalid
    // - 4720520625
    // - 9329704956
    // - 9488688496
    // - 9783051521
    // - 472052062
    // - 47205206251
    // - AS4720520625
    // - 4720520625AS
    // - 4720AS520625
    // - AS47205206
    // - 4720AS0625
    // - 47205206AS
    
    // MARK: - Init
    
    func testInitWithIntArray() {
        let validator = VATIdValidator([5, 2, 6, 0, 2, 5, 0, 2, 7, 4])
        
        XCTAssertEqual(validator.vatId, [5, 2, 6, 0, 2, 5, 0, 2, 7, 4])
    }
    
    func testInitWithInt() {
        let validator = VATIdValidator(Int(5260250274))
        
        XCTAssertEqual(validator.vatId, [5, 2, 6, 0, 2, 5, 0, 2, 7, 4])
    }
    
    func testInitWithInt64() {
        let validator = VATIdValidator(Int64(5260250274))
        
        XCTAssertEqual(validator.vatId, [5, 2, 6, 0, 2, 5, 0, 2, 7, 4])
    }
    
    func testInitWithUInt() {
        let validator = VATIdValidator(UInt(5260250274))
        
        XCTAssertEqual(validator.vatId, [5, 2, 6, 0, 2, 5, 0, 2, 7, 4])
    }
    
    func testInitWithUInt64() {
        let validator = VATIdValidator(UInt64(5260250274))
        
        XCTAssertEqual(validator.vatId, [5, 2, 6, 0, 2, 5, 0, 2, 7, 4])
    }

    func testInitWithDouble() {
        let validator = VATIdValidator(Double(5260250274))
        
        XCTAssertEqual(validator.vatId, [5, 2, 6, 0, 2, 5, 0, 2, 7, 4])
    }
    
    func testInitWithString() {
        let validator = VATIdValidator("5260250274")
        
        XCTAssertEqual(validator.vatId, [5, 2, 6, 0, 2, 5, 0, 2, 7, 4])
    }
    
    // MARK: - Check sum
    
    func testChecksumMinistryOfFinanceVATId() {
        let validator = VATIdValidator(5260250274)
        
        XCTAssertEqual(validator.checkSum(), 4)
    }
    
    func testChecksumChancelleryOfThePrimeMinisterVATId() {
        let validator = VATIdValidator(5261645000)
        
        XCTAssertEqual(validator.checkSum(), 0)
    }
    
    func testChecksumWithInvalidVATId() {
        // This test doesn't check the correctness of the checksum.
        ["472052062",
         "47205206251",
         "AS4720520625",
         "4720520625AS",
         "4720AS520625",
         "AS47205206",
         "4720AS0625",
         "47205206AS"].forEach { XCTAssertNil(VATIdValidator($0).checkSum(), "\($0) should be nil") }
    }
    
    // MARK: - Validation
    
    func testValidationMinistryOfFinanceVATId() {
        let validator = VATIdValidator(5260250274)
        
        XCTAssertNoThrow(try validator.validate())
    }
    
    func testValidationChancelleryOfThePrimeMinisterVATId() {
        let validator = VATIdValidator(5261645000)
        
        XCTAssertNoThrow(try validator.validate())
    }
    
    func testValidationWithIncorectLength() {
        ["47205206251",
         "AS4720520625",
         "4720520625AS",
         "4720AS520625",
         "AS47205206",
         "4720AS0625",
         "47205206AS"].forEach { vatId in
            do {
                try VATIdValidator(vatId).validate()
                XCTFail("\(vatId) should throw error")
            } catch let error {
                guard error as? ValidationError == ValidationError.incorrectLength else {
                    XCTFail("\(vatId) should throw ValidationError.incorrectLength error")
                    
                    return
                }
            }
        }
    }
   
    func testValidationWithChceckSumNotMatch() {
        ["4720520625",
         "9329704956",
         "9488688496",
         "9783051521"].forEach { vatId in
            do {
                try VATIdValidator(vatId).validate()
                XCTFail("\(vatId) should throw error")
            } catch let error {
                guard error as? ValidationError == ValidationError.checkSumNotMatch else {
                    XCTFail("\(vatId) should throw ValidationError.checkSumNotMatch error")
                    
                    return
                }
            }
        }
    }
    
    // MARK: - Extensions
    
    func testBinaryIntegerExtensionIsValidTrue() {
        XCTAssertTrue(5260250274.isValidVATId)
    }
    
    func testBinaryIntegerExtensionIsValidFalse() {
        XCTAssertFalse(4720520625.isValidVATId)
    }

    func testStringLiteralTypeExtensionIsValidTrue() {
        XCTAssertTrue("5260250274".isValidVATId)
    }
    
    func testStringLiteralTypeExtensionIsValidFalse() {
        XCTAssertFalse("4720520625".isValidVATId)
    }
    
    func testDoubleExtensionIsValidTrue() {
        XCTAssertTrue(Double(5260250274).isValidVATId)
    }
    
    func testDoubleExtensionIsValidFalse() {
        XCTAssertFalse(Double(4720520625).isValidVATId)
    }
    
}

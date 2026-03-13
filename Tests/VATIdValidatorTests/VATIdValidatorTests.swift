import Testing
@testable import VATIdValidator

@Suite
struct VATIdValidatorTests {

    typealias ValidationError = VATIdValidator.ValidationError

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

    @Test func initWithIntArray() {
        let validator = VATIdValidator([5, 2, 6, 0, 2, 5, 0, 2, 7, 4])

        #expect(validator.vatId == [5, 2, 6, 0, 2, 5, 0, 2, 7, 4])
    }

    @Test func initWithInt() {
        let validator = VATIdValidator(Int(5260250274))

        #expect(validator.vatId == [5, 2, 6, 0, 2, 5, 0, 2, 7, 4])
    }

    @Test func initWithInt64() {
        let validator = VATIdValidator(Int64(5260250274))

        #expect(validator.vatId == [5, 2, 6, 0, 2, 5, 0, 2, 7, 4])
    }

    @Test func initWithUInt() {
        let validator = VATIdValidator(UInt(5260250274))

        #expect(validator.vatId == [5, 2, 6, 0, 2, 5, 0, 2, 7, 4])
    }

    @Test func initWithUInt64() {
        let validator = VATIdValidator(UInt64(5260250274))

        #expect(validator.vatId == [5, 2, 6, 0, 2, 5, 0, 2, 7, 4])
    }

    @Test func initWithDouble() {
        let validator = VATIdValidator(Double(5260250274))

        #expect(validator.vatId == [5, 2, 6, 0, 2, 5, 0, 2, 7, 4])
    }

    @Test func initWithString() {
        let validator = VATIdValidator("5260250274")

        #expect(validator.vatId == [5, 2, 6, 0, 2, 5, 0, 2, 7, 4])
    }

    // MARK: - Check sum

    @Test func checksumMinistryOfFinanceVATId() {
        let validator = VATIdValidator(5260250274)

        #expect(validator.checkSum() == 4)
    }

    @Test func checksumChancelleryOfThePrimeMinisterVATId() {
        let validator = VATIdValidator(5261645000)

        #expect(validator.checkSum() == 0)
    }

    @Test(arguments: [
        "472052062",
        "47205206251",
        "AS4720520625",
        "4720520625AS",
        "4720AS520625",
        "AS47205206",
        "4720AS0625",
        "47205206AS"
    ])
    func checksumWithInvalidVATId(vatId: String) {
        #expect(VATIdValidator(vatId).checkSum() == nil)
    }

    // MARK: - Validation

    @Test func validationMinistryOfFinanceVATId() throws {
        let validator = VATIdValidator(5260250274)

        try validator.validate()
    }

    @Test func validationChancelleryOfThePrimeMinisterVATId() throws {
        let validator = VATIdValidator(5261645000)

        try validator.validate()
    }

    @Test(arguments: [
        "47205206251",
        "AS4720520625",
        "4720520625AS",
        "4720AS520625",
        "AS47205206",
        "4720AS0625",
        "47205206AS"
    ])
    func validationWithIncorrectLength(vatId: String) {
        #expect(throws: ValidationError.incorrectLength) {
            try VATIdValidator(vatId).validate()
        }
    }

    @Test(arguments: [
        "4720520625",
        "9329704956",
        "9488688496",
        "9783051521"
    ])
    func validationWithCheckSumNotMatch(vatId: String) {
        #expect(throws: ValidationError.checkSumNotMatch) {
            try VATIdValidator(vatId).validate()
        }
    }

    // MARK: - Extensions

    @Test func binaryIntegerExtensionIsValidTrue() {
        #expect(5260250274.isValidVATId)
    }

    @Test func binaryIntegerExtensionIsValidFalse() {
        #expect(!4720520625.isValidVATId)
    }

    @Test func stringLiteralTypeExtensionIsValidTrue() {
        #expect("5260250274".isValidVATId)
    }

    @Test func stringLiteralTypeExtensionIsValidFalse() {
        #expect(!"4720520625".isValidVATId)
    }

    @Test func doubleExtensionIsValidTrue() {
        #expect(Double(5260250274).isValidVATId)
    }

    @Test func doubleExtensionIsValidFalse() {
        #expect(!Double(4720520625).isValidVATId)
    }
}

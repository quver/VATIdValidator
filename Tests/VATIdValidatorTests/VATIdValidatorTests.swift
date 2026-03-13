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

    @Test func initWithIntArray() throws {
        try VATIdValidator([5, 2, 6, 0, 2, 5, 0, 2, 7, 4]).validate()
    }

    @Test func initWithInt() throws {
        try VATIdValidator(Int(5260250274)).validate()
    }

    @Test func initWithInt64() throws {
        try VATIdValidator(Int64(5260250274)).validate()
    }

    @Test func initWithUInt() throws {
        try VATIdValidator(UInt(5260250274)).validate()
    }

    @Test func initWithUInt64() throws {
        try VATIdValidator(UInt64(5260250274)).validate()
    }

    @Test func initWithDouble() throws {
        try VATIdValidator(Double(5260250274)).validate()
    }

    @Test func initWithString() throws {
        try VATIdValidator("5260250274").validate()
    }

    // MARK: - Validation

    @Test func validationMinistryOfFinanceVATId() throws {
        try VATIdValidator(5260250274).validate()
    }

    @Test func validationChancelleryOfThePrimeMinisterVATId() throws {
        try VATIdValidator(5261645000).validate()
    }

    @Test(arguments: [
        "47205206251",
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
        [1, 2, 3, 4, 5, 6, 7, 8, 99, 0],
        [5, 2, 6, 0, 2, 5, 0, 2, -1, 4]
    ])
    func validationWithInvalidDigit(digits: [Int]) {
        #expect(throws: ValidationError.invalidDigit) {
            try VATIdValidator(digits).validate()
        }
    }

    // Digits stripped from dashes/spaces yield a valid VAT ID — validate() passes
    @Test(arguments: [
        "526-025-02-74",
        "526 025 02 74",
        "52-60-25-02-74",
        "5260 250274"
    ])
    func validationWithDashesAndSpacesValid(vatId: String) throws {
        try VATIdValidator(vatId).validate()
    }

    // Digits stripped from dashes/spaces yield an invalid VAT ID — checksum mismatch
    @Test(arguments: [
        "472-052-06-25",
        "472 052 0625",
        "47-20-52-06-25"
    ])
    func validationWithDashesAndSpacesInvalid(vatId: String) {
        #expect(throws: ValidationError.checkSumNotMatch) {
            try VATIdValidator(vatId).validate()
        }
    }

    @Test(arguments: [
        "4720520625",
        "9329704956",
        "9488688496",
        "9783051521",
        "AS4720520625",
        "4720520625AS",
        "4720AS520625"
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

    @Test func stringExtensionIsValidTrue() {
        #expect("5260250274".isValidVATId)
    }

    @Test func stringExtensionIsValidFalse() {
        #expect(!"4720520625".isValidVATId)
    }

    @Test func doubleExtensionIsValidTrue() {
        #expect(Double(5260250274).isValidVATId)
    }

    @Test func doubleExtensionIsValidFalse() {
        #expect(!Double(4720520625).isValidVATId)
    }
}

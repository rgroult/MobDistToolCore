#if !canImport(ObjectiveC)
import XCTest

extension AppTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__AppTests = [
        ("testNothing", testNothing),
    ]
}

extension ApplicationServiceTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__ApplicationServiceTests = [
        ("testCreateApplication", testCreateApplication),
        ("testDeleteApplication", testDeleteApplication),
        ("testExistingApp", testExistingApp),
        ("testFindApplication", testFindApplication),
        ("testUpdateApplicationAdminUsers", testUpdateApplicationAdminUsers),
    ]
}

extension ApplicationsControllerTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__ApplicationsControllerTests = [
        ("testAddAdminUser", testAddAdminUser),
        ("testAddAdminUserInvalid", testAddAdminUserInvalid),
        ("testAddAdminUserUnAuthorized", testAddAdminUserUnAuthorized),
        ("testAllApplications", testAllApplications),
        ("testAllApplicationsMultipleUsers", testAllApplicationsMultipleUsers),
        ("testAppDetail", testAppDetail),
        ("testAppDetailNotAdmin", testAppDetailNotAdmin),
        ("testCreate", testCreate),
        ("testCreateMultiple", testCreateMultiple),
        ("testCreateTwiceError", testCreateTwiceError),
        ("testDeleteApplication", testDeleteApplication),
        ("testDeleteApplicationKO", testDeleteApplicationKO),
        ("testFilterApplications", testFilterApplications),
        ("testFilterApplicationsBadPlatform", testFilterApplicationsBadPlatform),
        ("testRemoveAdminUser", testRemoveAdminUser),
        ("testRemoveAdminUserInvalid", testRemoveAdminUserInvalid),
        ("testRemoveAdminUserUnAuthorized", testRemoveAdminUserUnAuthorized),
        ("testRetrieveVersion", testRetrieveVersion),
        ("testRetrieveVersions", testRetrieveVersions),
        ("testRetrieveVersionsByBranchAndLatest", testRetrieveVersionsByBranchAndLatest),
        ("testRetrieveVersionsByBranch", testRetrieveVersionsByBranch),
        ("testRetrieveVersionsByPages", testRetrieveVersionsByPages),
        ("testRetrieveVersionsLatest", testRetrieveVersionsLatest),
        ("testUpdateApplication", testUpdateApplication),
        ("testUpdateApplicationNotAdmin", testUpdateApplicationNotAdmin),
    ]
}

extension ArtifactsContollerTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__ArtifactsContollerTests = [
        ("testBadContentType2", testBadContentType2),
        ("testBadContentType", testBadContentType),
        ("testCreateApkArtifact", testCreateApkArtifact),
        ("testCreateApkArtifactFullArgs", testCreateApkArtifactFullArgs),
        ("testCreateArtifactBadApiKey", testCreateArtifactBadApiKey),
        ("testCreateArtifactBigFile", testCreateArtifactBigFile),
        ("testCreateIpaArtifact", testCreateIpaArtifact),
        ("testCreateIpaArtifactFullArgs", testCreateIpaArtifactFullArgs),
        ("testCreateIpaArtifactWithSortIdentifier", testCreateIpaArtifactWithSortIdentifier),
        ("testCreateLastArtifact", testCreateLastArtifact),
        ("testCreateLastArtifactFullArgs", testCreateLastArtifactFullArgs),
        ("testCreateSameArtifact", testCreateSameArtifact),
        ("testCreateWithApiKey", testCreateWithApiKey),
        ("testDeleteArtifact", testDeleteArtifact),
        ("testDeleteArtifactBasApiKey", testDeleteArtifactBasApiKey),
        ("testDeleteArtifactNotFound", testDeleteArtifactNotFound),
        ("testDeleteArtifactTwice", testDeleteArtifactTwice),
        ("testDownloadAndroidDownloadFile", testDownloadAndroidDownloadFile),
        ("testDownloadInfo", testDownloadInfo),
        ("testDownloadiOSDownloadFile", testDownloadiOSDownloadFile),
        ("testDownloadiOSManifest", testDownloadiOSManifest),
    ]
}

extension LocalStorageServiceTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__LocalStorageServiceTests = [
        ("testDeleteFile", testDeleteFile),
        ("testInitStoreFile", testInitStoreFile),
        ("testStoreBigFile", testStoreBigFile),
        ("testStoreFile", testStoreFile),
    ]
}

extension RandomTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__RandomTests = [
        ("testRandom", testRandom),
        ("testRandom2", testRandom2),
    ]
}

extension TokenInfoServiceTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__TokenInfoServiceTests = [
        ("testCreateAndRetrieveToken", testCreateAndRetrieveToken),
        ("testCreateToken", testCreateToken),
        ("testExpiredDuration", testExpiredDuration),
        ("testExpiredPurge", testExpiredPurge),
        ("testPurgeAll", testPurgeAll),
    ]
}

extension UsersControllerAutomaticRegistrationTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__UsersControllerAutomaticRegistrationTests = [
        ("testForgotPassword", testForgotPassword),
        ("testLogin", testLogin),
        ("testRegister", testRegister),
    ]
}

extension UsersControllerNoAutomaticRegistrationTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__UsersControllerNoAutomaticRegistrationTests = [
        ("testActivation", testActivation),
        ("testActivationKO", testActivationKO),
        ("testForgotPassword", testForgotPassword),
        ("testForgotPasswordCheckAccountIsDisabled", testForgotPasswordCheckAccountIsDisabled),
        ("testForgotPasswordKO", testForgotPasswordKO),
        ("testLogin", testLogin),
        ("testLoginKo", testLoginKo),
        ("testLoginNotActivated", testLoginNotActivated),
        ("testMe", testMe),
        ("testRegister", testRegister),
    ]
}

extension UsersServiceTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__UsersServiceTests = [
        ("testAdminUser", testAdminUser),
        ("testCreateActivatedUser", testCreateActivatedUser),
        ("testCreateIdenticalUser", testCreateIdenticalUser),
        ("testCreateNormalUser", testCreateNormalUser),
        ("testDeleteTwice", testDeleteTwice),
        ("testLoginUser", testLoginUser),
        ("testLoginUserFailed", testLoginUserFailed),
        ("testResetUser", testResetUser),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AppTests.__allTests__AppTests),
        testCase(ApplicationServiceTests.__allTests__ApplicationServiceTests),
        testCase(ApplicationsControllerTests.__allTests__ApplicationsControllerTests),
        testCase(ArtifactsContollerTests.__allTests__ArtifactsContollerTests),
        testCase(LocalStorageServiceTests.__allTests__LocalStorageServiceTests),
        testCase(RandomTests.__allTests__RandomTests),
        testCase(TokenInfoServiceTests.__allTests__TokenInfoServiceTests),
        testCase(UsersControllerAutomaticRegistrationTests.__allTests__UsersControllerAutomaticRegistrationTests),
        testCase(UsersControllerNoAutomaticRegistrationTests.__allTests__UsersControllerNoAutomaticRegistrationTests),
        testCase(UsersServiceTests.__allTests__UsersServiceTests),
    ]
}
#endif

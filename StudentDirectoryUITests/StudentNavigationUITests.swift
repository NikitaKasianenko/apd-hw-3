import XCTest

/// Navigation checks driven only by the fixed seed data and accessibility identifiers.
final class StudentNavigationUITests: XCTestCase {
    private let timeout: TimeInterval = 10
    private let adaCell = "studentCell.00000000-0000-0000-0000-000000000001"
    private let alanCell = "studentCell.00000000-0000-0000-0000-000000000002"
    private let katherineCell = "studentCell.00000000-0000-0000-0000-000000000004"
    private let donaldCell = "studentCell.00000000-0000-0000-0000-000000000007"

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func testStudentListShowsSeedStudents() {
        let app = launch()

        XCTAssertTrue(app.navigationBars["Students"].waitForExistence(timeout: timeout))
        let list = app.tables["studentList"]
        XCTAssertTrue(list.exists)
        let ada = list.cells[adaCell]
        XCTAssertTrue(ada.exists)
        XCTAssertTrue(ada.staticTexts["Ada Lovelace"].exists)
        XCTAssertTrue(ada.staticTexts["Average grade: 97.5"].exists)
        XCTAssertTrue(ada.staticTexts["Scholarship: Yes"].exists)
    }

    @MainActor
    func testTappingStudentOpensDetailsAndBackReturns() {
        let app = launch()
        app.tables["studentList"].cells[katherineCell].tap()

        let details = app.scrollViews["studentDetails"]
        XCTAssertTrue(details.waitForExistence(timeout: timeout))
        XCTAssertTrue(details.staticTexts["Katherine Johnson"].exists)
        XCTAssertTrue(details.staticTexts["Age: 20"].exists)
        XCTAssertTrue(details.staticTexts["Average grade: 99.0"].exists)
        XCTAssertTrue(details.staticTexts["Scholarship: Yes"].exists)
        XCTAssertTrue(details.buttons["subjectButton.Math"].exists)
        XCTAssertTrue(details.buttons["subjectButton.Physics"].exists)
        XCTAssertFalse(details.buttons["subjectButton.Design"].exists)

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Students"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tables["studentList"].cells[katherineCell].exists)
    }

    @MainActor
    func testSubjectButtonOpensFilteredListInStoreOrder() {
        let app = launch()
        app.tables["studentList"].cells[adaCell].tap()
        let mathButton = app.buttons["subjectButton.Math"]
        XCTAssertTrue(mathButton.waitForExistence(timeout: timeout))
        mathButton.tap()

        XCTAssertTrue(app.navigationBars["Math"].waitForExistence(timeout: timeout))
        let list = app.tables["studentList"]
        XCTAssertEqual(list.cells.count, 3)
        XCTAssertEqual(list.cells.element(boundBy: 0).identifier, adaCell)
        XCTAssertEqual(list.cells.element(boundBy: 1).identifier, katherineCell)
        XCTAssertEqual(list.cells.element(boundBy: 2).identifier, donaldCell)
        XCTAssertFalse(list.cells[alanCell].exists)

        app.navigationBars["Math"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.scrollViews["studentDetails"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.scrollViews["studentDetails"].staticTexts["Ada Lovelace"].exists)
    }

    @MainActor
    func testFilteredRowOpensThatStudentsDetails() {
        let app = launch()
        app.tables["studentList"].cells[adaCell].tap()
        let mathButton = app.buttons["subjectButton.Math"]
        XCTAssertTrue(mathButton.waitForExistence(timeout: timeout))
        mathButton.tap()

        let donald = app.tables["studentList"].cells[donaldCell]
        XCTAssertTrue(donald.waitForExistence(timeout: timeout))
        donald.tap()

        let details = app.scrollViews["studentDetails"]
        XCTAssertTrue(details.staticTexts["Donald Knuth"].waitForExistence(timeout: timeout))
        XCTAssertTrue(details.staticTexts["Scholarship: No"].exists)
        XCTAssertTrue(details.buttons["subjectButton.Algorithms"].exists)
    }

    @MainActor
    func testFlowWorksWithLargestAccessibilityTextSize() {
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()

        let ada = app.tables["studentList"].cells[adaCell]
        XCTAssertTrue(ada.waitForExistence(timeout: timeout))
        XCTAssertTrue(ada.staticTexts["Ada Lovelace"].exists)
        ada.tap()

        let details = app.scrollViews["studentDetails"]
        XCTAssertTrue(details.waitForExistence(timeout: timeout))
        XCTAssertTrue(details.staticTexts["Ada Lovelace"].exists)
        XCTAssertTrue(details.buttons["subjectButton.Algorithms"].exists)
    }

    @MainActor
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }
}

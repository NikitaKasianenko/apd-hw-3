import XCTest

/// Bonus add/edit/delete flows. Every launch starts from the fixed seed data.
final class StudentMutationUITests: XCTestCase {
    private let timeout: TimeInterval = 10
    private let adaCell = "studentCell.00000000-0000-0000-0000-000000000001"
    private let alanCell = "studentCell.00000000-0000-0000-0000-000000000002"
    private let graceCell = "studentCell.00000000-0000-0000-0000-000000000003"

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func testAddStudentShowsNewRowInList() {
        let app = launch()
        app.buttons["addStudentButton"].tap()

        let name = app.textFields["studentNameField"]
        XCTAssertTrue(name.waitForExistence(timeout: timeout))
        name.tap()
        name.typeText("Linus Torvalds")
        let age = app.textFields["studentAgeField"]
        age.tap()
        age.typeText("19")
        app.buttons["saveStudentButton"].tap()

        let list = app.tables["studentList"]
        XCTAssertTrue(list.staticTexts["Linus Torvalds"].waitForExistence(timeout: timeout))
        XCTAssertTrue(list.staticTexts["Scholarship: No"].exists)
    }

    @MainActor
    func testInvalidAgeShowsErrorAndSavesNothing() {
        let app = launch()
        app.buttons["addStudentButton"].tap()

        let name = app.textFields["studentNameField"]
        XCTAssertTrue(name.waitForExistence(timeout: timeout))
        name.tap()
        name.typeText("Nobody Here")
        let age = app.textFields["studentAgeField"]
        age.tap()
        age.typeText("0")
        app.buttons["saveStudentButton"].tap()

        let alert = app.alerts["Cannot Save"]
        XCTAssertTrue(alert.waitForExistence(timeout: timeout))
        XCTAssertTrue(alert.staticTexts["Age must be greater than 0."].exists)
        alert.buttons["OK"].tap()
        app.buttons["cancelStudentFormButton"].tap()

        let list = app.tables["studentList"]
        XCTAssertTrue(app.navigationBars["Students"].waitForExistence(timeout: timeout))
        list.swipeUp()
        list.swipeUp()
        XCTAssertTrue(list.cells["studentCell.00000000-0000-0000-0000-000000000010"].exists)
        XCTAssertFalse(list.staticTexts["Nobody Here"].exists)
    }

    @MainActor
    func testEditStudentRefreshesDetailsAndList() {
        let app = launch()
        app.tables["studentList"].cells[adaCell].tap()
        let edit = app.buttons["editStudentButton"]
        XCTAssertTrue(edit.waitForExistence(timeout: timeout))
        edit.tap()

        let name = app.textFields["studentNameField"]
        XCTAssertTrue(name.waitForExistence(timeout: timeout))
        XCTAssertEqual(name.value as? String, "Ada Lovelace")
        name.tap()
        let clear = name.buttons["Clear text"]
        XCTAssertTrue(clear.waitForExistence(timeout: timeout))
        clear.tap()
        name.typeText("Ada King")
        app.buttons["saveStudentButton"].tap()

        let details = app.scrollViews["studentDetails"]
        XCTAssertTrue(details.staticTexts["Ada King"].waitForExistence(timeout: timeout))
        XCTAssertFalse(details.staticTexts["Ada Lovelace"].exists)

        app.navigationBars.buttons.element(boundBy: 0).tap()
        let cell = app.tables["studentList"].cells[adaCell]
        XCTAssertTrue(cell.waitForExistence(timeout: timeout))
        XCTAssertTrue(cell.staticTexts["Ada King"].exists)
    }

    @MainActor
    func testSwipeToDeleteRemovesStudent() {
        let app = launch()
        let list = app.tables["studentList"]
        let alan = list.cells[alanCell]
        XCTAssertTrue(alan.waitForExistence(timeout: timeout))

        alan.swipeLeft()
        let delete = list.buttons["Delete"]
        XCTAssertTrue(delete.waitForExistence(timeout: timeout))
        delete.tap()

        XCTAssertTrue(list.cells[adaCell].exists)
        XCTAssertTrue(list.cells[graceCell].exists)
        XCTAssertFalse(list.cells[alanCell].exists)
        XCTAssertEqual(list.cells.element(boundBy: 1).identifier, graceCell)
    }

    @MainActor
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }
}

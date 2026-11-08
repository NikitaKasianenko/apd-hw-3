import UIKit
import XCTest
@testable import StudentDirectory

@MainActor
final class StudentControllerTests: XCTestCase {
    private let adaID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")

    func testMainListShowsEveryStudentWithStudentsTitle() throws {
        let store = StudentStore()
        let list = StudentListViewController(store: store, mode: .all)
        list.loadViewIfNeeded()

        XCTAssertEqual(list.title, "Students")
        XCTAssertEqual(list.tableView.accessibilityIdentifier, "studentList")
        XCTAssertEqual(list.tableView.numberOfRows(inSection: 0), 10)

        let cell = try XCTUnwrap(cell(in: list, row: 0))
        XCTAssertEqual(cell.accessibilityIdentifier, "studentCell.00000000-0000-0000-0000-000000000001")
        XCTAssertEqual(cell.nameLabel.text, "Ada Lovelace")
        XCTAssertEqual(cell.ageLabel.text, "Age: 20")
        XCTAssertEqual(cell.gradeLabel.text, "Average grade: 97.5")
        XCTAssertEqual(cell.scholarshipLabel.text, "Scholarship: Yes")
        XCTAssertNotNil(cell.avatarView.image)
    }

    func testSubjectListShowsOnlyMatchingStudentsInStoreOrder() throws {
        let store = StudentStore()
        let list = StudentListViewController(store: store, mode: .subject("Physics"))
        list.loadViewIfNeeded()

        XCTAssertEqual(list.title, "Physics")
        XCTAssertEqual(list.tableView.numberOfRows(inSection: 0), 4)
        let names = try (0..<4).map { try XCTUnwrap(cell(in: list, row: $0)).nameLabel.text }
        XCTAssertEqual(names, ["Alan Turing", "Katherine Johnson", "Mary Jackson", "Tim Berners-Lee"])
    }

    func testSelectingRowPushesDetailsSharingTheSameStore() throws {
        let store = StudentStore()
        let list = StudentListViewController(store: store, mode: .all)
        let navigation = UINavigationController(rootViewController: list)
        list.loadViewIfNeeded()

        list.tableView(list.tableView, didSelectRowAt: IndexPath(row: 3, section: 0))

        let details = try XCTUnwrap(navigation.viewControllers.last as? StudentDetailViewController)
        XCTAssertTrue(details.store === store)
        XCTAssertEqual(details.studentID, store.students[3].id)
    }

    func testDetailsShowEveryFieldAndOneButtonPerSubject() throws {
        let store = StudentStore()
        let id = try XCTUnwrap(adaID)
        let details = StudentDetailViewController(store: store, studentID: id)
        details.loadViewIfNeeded()

        XCTAssertEqual(details.scrollView.accessibilityIdentifier, "studentDetails")
        XCTAssertEqual(details.title, "Ada Lovelace")
        XCTAssertEqual(details.nameLabel.text, "Ada Lovelace")
        XCTAssertEqual(details.ageLabel.text, "Age: 20")
        XCTAssertEqual(details.gradeLabel.text, "Average grade: 97.5")
        XCTAssertEqual(details.scholarshipLabel.text, "Scholarship: Yes")
        XCTAssertEqual(details.idLabel.text, "Student ID: 00000000-0000-0000-0000-000000000001")
        XCTAssertNotNil(details.avatarView.image)
        XCTAssertEqual(details.subjectButtons.map(\.accessibilityIdentifier),
                       ["subjectButton.Algorithms", "subjectButton.Math", "subjectButton.Design"])
    }

    func testSubjectButtonPushesFilteredListWithSubjectTitle() throws {
        let store = StudentStore()
        let id = try XCTUnwrap(adaID)
        let details = StudentDetailViewController(store: store, studentID: id)
        let navigation = UINavigationController(rootViewController: details)
        details.loadViewIfNeeded()

        let mathButton = try XCTUnwrap(details.subjectButtons.first { $0.accessibilityIdentifier == "subjectButton.Math" })
        mathButton.sendActions(for: .primaryActionTriggered)

        let list = try XCTUnwrap(navigation.viewControllers.last as? StudentListViewController)
        XCTAssertEqual(list.mode, .subject("Math"))
        XCTAssertEqual(list.title, "Math")
        XCTAssertTrue(list.store === store)
        XCTAssertEqual(list.visibleStudents.map(\.name), ["Ada Lovelace", "Katherine Johnson", "Donald Knuth"])
    }

    func testListReadsFromSharedStoreInsteadOfKeepingACopy() throws {
        let store = StudentStore()
        let list = StudentListViewController(store: store, mode: .subject("Math"))
        list.loadViewIfNeeded()
        XCTAssertEqual(list.tableView.numberOfRows(inSection: 0), 3)

        try store.deleteStudent(id: try XCTUnwrap(adaID))
        list.tableView.reloadData()

        XCTAssertEqual(list.tableView.numberOfRows(inSection: 0), 2)
        XCTAssertEqual(list.visibleStudents.map(\.name), ["Katherine Johnson", "Donald Knuth"])
    }

    func testTextUsesDynamicTypeFonts() throws {
        let list = StudentListViewController(store: StudentStore(), mode: .all)
        list.loadViewIfNeeded()
        let cell = try XCTUnwrap(cell(in: list, row: 0))
        let details = StudentDetailViewController(store: StudentStore(), studentID: try XCTUnwrap(adaID))
        details.loadViewIfNeeded()

        let labels = [cell.nameLabel, cell.ageLabel, cell.gradeLabel, cell.scholarshipLabel,
                      details.nameLabel, details.ageLabel, details.gradeLabel, details.scholarshipLabel, details.idLabel]
        for label in labels {
            XCTAssertTrue(label.adjustsFontForContentSizeCategory, "\(label.text ?? "") does not scale")
            XCTAssertEqual(label.numberOfLines, 0, "\(label.text ?? "") is truncated")
        }
    }

    private func cell(in list: StudentListViewController, row: Int) -> StudentCell? {
        list.tableView.dataSource?.tableView(list.tableView, cellForRowAt: IndexPath(row: row, section: 0)) as? StudentCell
    }
}

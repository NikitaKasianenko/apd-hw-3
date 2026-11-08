import UIKit
import XCTest
@testable import StudentDirectory

@MainActor
final class StudentMutationTests: XCTestCase {
    private let adaID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")
    private let unknownID = UUID(uuidString: "00000000-0000-0000-0000-0000000000FF")

    // MARK: - Store

    func testAddStudentAppendsStudentWithDefaults() throws {
        let store = StudentStore()
        let seedIDs = Set(StudentSeedData.students.map(\.id))

        try store.addStudent(name: "Linus Torvalds", age: 19)

        XCTAssertEqual(store.students.count, 11)
        XCTAssertEqual(Array(store.students.prefix(10)), StudentSeedData.students)
        let added = try XCTUnwrap(store.students.last)
        XCTAssertFalse(seedIDs.contains(added.id))
        XCTAssertEqual(added.name, "Linus Torvalds")
        XCTAssertEqual(added.age, 19)
        XCTAssertEqual(added.averageGrade, 0)
        XCTAssertFalse(added.isScholarshipHolder)
        XCTAssertEqual(added.subjects, [])
        XCTAssertEqual(added.avatarName, "avatar-default")
    }

    func testInvalidAddDoesNotMutateStore() {
        let store = StudentStore()

        XCTAssertThrowsError(try store.addStudent(name: "   ", age: 20)) { error in
            XCTAssertEqual(error as? StudentStoreError, .blankName)
        }
        XCTAssertThrowsError(try store.addStudent(name: "Valid Name", age: 0)) { error in
            XCTAssertEqual(error as? StudentStoreError, .nonPositiveAge)
        }
        XCTAssertThrowsError(try store.addStudent(name: "Valid Name", age: -3))
        XCTAssertEqual(store.students, StudentSeedData.students)
    }

    func testUpdateChangesOnlyNameAndAge() throws {
        let store = StudentStore()
        let id = try XCTUnwrap(adaID)
        let before = try XCTUnwrap(store.student(id: id))

        try store.updateStudent(id: id, name: "Ada King", age: 27)

        let after = try XCTUnwrap(store.student(id: id))
        XCTAssertEqual(after.name, "Ada King")
        XCTAssertEqual(after.age, 27)
        XCTAssertEqual(after.averageGrade, before.averageGrade)
        XCTAssertEqual(after.isScholarshipHolder, before.isScholarshipHolder)
        XCTAssertEqual(after.subjects, before.subjects)
        XCTAssertEqual(after.avatarName, before.avatarName)
        XCTAssertEqual(store.students.firstIndex { $0.id == id }, 0)
    }

    func testInvalidUpdateAndUnknownIDsDoNotMutateStore() throws {
        let store = StudentStore()
        let id = try XCTUnwrap(adaID)
        let unknown = try XCTUnwrap(unknownID)

        XCTAssertThrowsError(try store.updateStudent(id: id, name: "", age: 20))
        XCTAssertThrowsError(try store.updateStudent(id: id, name: "Ada", age: 0))
        XCTAssertThrowsError(try store.updateStudent(id: unknown, name: "Ghost", age: 30)) { error in
            XCTAssertEqual(error as? StudentStoreError, .unknownID(unknown))
        }
        XCTAssertThrowsError(try store.deleteStudent(id: unknown)) { error in
            XCTAssertEqual(error as? StudentStoreError, .unknownID(unknown))
        }
        XCTAssertEqual(store.students, StudentSeedData.students)
    }

    // MARK: - Controllers

    func testFormAddsStudentAndRejectsInvalidInputWithoutSaving() {
        let store = StudentStore()
        let form = StudentFormViewController(store: store, mode: .add)
        var saveCount = 0
        form.onSave = { saveCount += 1 }
        form.loadViewIfNeeded()

        form.nameField.text = "Margaret Hamilton"
        form.ageField.text = "abc"
        XCTAssertEqual(form.save(), "Age must be a whole number.")
        form.ageField.text = "0"
        XCTAssertEqual(form.save(), "Age must be greater than 0.")
        form.nameField.text = "  "
        form.ageField.text = "33"
        XCTAssertEqual(form.save(), "Name must not be blank.")
        XCTAssertEqual(store.students.count, 10)
        XCTAssertEqual(saveCount, 0)

        form.nameField.text = "  Margaret Hamilton "
        XCTAssertNil(form.save())
        XCTAssertEqual(saveCount, 1)
        XCTAssertEqual(store.students.last?.name, "Margaret Hamilton")
        XCTAssertEqual(store.students.last?.age, 33)
    }

    func testEditFormIsPrefilledAndDetailsRefreshAfterSave() throws {
        let store = StudentStore()
        let id = try XCTUnwrap(adaID)
        let details = StudentDetailViewController(store: store, studentID: id)
        details.loadViewIfNeeded()
        let form = StudentFormViewController(store: store, mode: .edit(id))
        form.onSave = { details.render() }
        form.loadViewIfNeeded()

        XCTAssertEqual(form.nameField.text, "Ada Lovelace")
        XCTAssertEqual(form.ageField.text, "20")

        form.nameField.text = "Ada King"
        form.ageField.text = "28"
        XCTAssertNil(form.save())

        XCTAssertEqual(details.title, "Ada King")
        XCTAssertEqual(details.nameLabel.text, "Ada King")
        XCTAssertEqual(details.ageLabel.text, "Age: 28")
    }

    func testSwipeDeleteRemovesStudentFromSharedStoreAndTable() throws {
        let store = StudentStore()
        let list = StudentListViewController(store: store, mode: .subject("Math"))
        list.loadViewIfNeeded()

        let configuration = try XCTUnwrap(list.tableView(list.tableView, trailingSwipeActionsConfigurationForRowAt: IndexPath(row: 1, section: 0)))
        let delete = try XCTUnwrap(configuration.actions.first)
        XCTAssertEqual(delete.style, .destructive)
        var succeeded: Bool?
        delete.handler(delete, UIView()) { succeeded = $0 }

        XCTAssertEqual(succeeded, true)
        XCTAssertEqual(store.students.count, 9)
        XCTAssertNil(store.students.first { $0.name == "Katherine Johnson" })
        XCTAssertEqual(list.tableView.numberOfRows(inSection: 0), 2)
        XCTAssertEqual(list.visibleStudents.map(\.name), ["Ada Lovelace", "Donald Knuth"])
    }

    func testBonusControlsHaveRequiredIdentifiers() throws {
        let list = StudentListViewController(store: StudentStore(), mode: .all)
        list.loadViewIfNeeded()
        let subjectList = StudentListViewController(store: StudentStore(), mode: .subject("Math"))
        subjectList.loadViewIfNeeded()
        let details = StudentDetailViewController(store: StudentStore(), studentID: try XCTUnwrap(adaID))
        details.loadViewIfNeeded()

        XCTAssertEqual(list.navigationItem.rightBarButtonItem?.accessibilityIdentifier, "addStudentButton")
        XCTAssertNil(subjectList.navigationItem.rightBarButtonItem)
        XCTAssertEqual(details.navigationItem.rightBarButtonItem?.accessibilityIdentifier, "editStudentButton")
    }
}

import XCTest
@testable import StudentDirectory

@MainActor
final class StudentStoreTests: XCTestCase {
    private let adaID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")
    private let katherineID = UUID(uuidString: "00000000-0000-0000-0000-000000000004")
    private let donaldID = UUID(uuidString: "00000000-0000-0000-0000-000000000007")

    func testSubjectFilterIsExactCaseSensitiveAndKeepsStoreOrder() {
        let store = StudentStore()

        XCTAssertEqual(store.students(matchingSubject: "Math").map(\.id), [adaID, katherineID, donaldID].compactMap { $0 })
        XCTAssertEqual(store.students(matchingSubject: "math"), [])
        XCTAssertEqual(store.students(matchingSubject: "Mat"), [])
        XCTAssertEqual(store.students(matchingSubject: "Math "), [])
    }

    func testFilterFollowsStoreOrderForCustomData() {
        let first = makeStudent(name: "Zed", subjects: ["Art"])
        let second = makeStudent(name: "Amy", subjects: ["Music"])
        let third = makeStudent(name: "Bob", subjects: ["Music", "Art"])
        let store = StudentStore(students: [first, second, third])

        XCTAssertEqual(store.students(matchingSubject: "Art"), [first, third])
        XCTAssertEqual(store.students(matchingSubject: "Music"), [second, third])
    }

    func testLookupByIDReturnsStoredStudentOrNil() throws {
        let store = StudentStore()
        let id = try XCTUnwrap(adaID)

        XCTAssertEqual(store.student(id: id)?.name, "Ada Lovelace")
        XCTAssertNil(store.student(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000FF") ?? UUID()))
    }

    private func makeStudent(name: String, subjects: [String]) -> Student {
        Student(id: UUID(), name: name, age: 20, averageGrade: 80, isScholarshipHolder: false, subjects: subjects, avatarName: "avatar-default")
    }
}

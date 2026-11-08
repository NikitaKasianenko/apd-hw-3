import Foundation

/// Display strings shared by the list cell and the detail screen.
/// Grades use a fixed format so output does not depend on the device locale.
enum StudentFormatting {
    static func age(_ student: Student) -> String {
        "Age: \(student.age)"
    }

    static func grade(_ student: Student) -> String {
        "Average grade: " + String(format: "%.1f", student.averageGrade)
    }

    static func scholarship(_ student: Student) -> String {
        student.isScholarshipHolder ? "Scholarship: Yes" : "Scholarship: No"
    }

    static func summary(_ student: Student) -> String {
        [student.name, age(student), grade(student), scholarship(student)].joined(separator: ", ")
    }
}

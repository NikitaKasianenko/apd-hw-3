import SnapKit
import UIKit

/// Two-field name/age form used both to add a new student and to edit an
/// existing one. All validation and mutation go through the shared store.
final class StudentFormViewController: UIViewController {
    enum Mode: Equatable {
        case add
        case edit(UUID)
    }

    let store: StudentStore
    let mode: Mode
    /// Called after every successful save so the presenter can refresh.
    var onSave: (() -> Void)?

    let nameField = UITextField()
    let ageField = UITextField()
    private let nameLabel = StudentFormViewController.makeLabel(text: "Name")
    private let ageLabel = StudentFormViewController.makeLabel(text: "Age")

    init(store: StudentStore, mode: Mode) {
        self.store = store
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
        title = mode == .add ? "New Student" : "Edit Student"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setUpNavigationItems()
        setUpFields()
        setUpLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nameField.becomeFirstResponder()
    }

    /// Validates the fields and saves through the store.
    /// Returns a user-facing error message, or `nil` on success.
    @discardableResult
    func save() -> String? {
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let age = Self.parseAge(ageField.text) else {
            return "Age must be a whole number."
        }
        do {
            switch mode {
            case .add:
                try store.addStudent(name: name, age: age)
            case .edit(let id):
                try store.updateStudent(id: id, name: name, age: age)
            }
        } catch let error as StudentStoreError {
            return Self.message(for: error)
        } catch {
            return "The student could not be saved."
        }
        onSave?()
        return nil
    }

    static func parseAge(_ text: String?) -> Int? {
        guard let text else { return nil }
        return Int(text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    static func message(for error: StudentStoreError) -> String {
        switch error {
        case .blankName:
            return "Name must not be blank."
        case .nonPositiveAge:
            return "Age must be greater than 0."
        case .unknownID:
            return "This student is no longer in the directory."
        }
    }

    // MARK: - Actions

    private func saveTapped() {
        if let message = save() {
            let alert = UIAlertController(title: "Cannot Save", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    // MARK: - Layout

    private func setUpNavigationItems() {
        let cancel = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        })
        cancel.accessibilityIdentifier = "cancelStudentFormButton"
        let save = UIBarButtonItem(systemItem: .save, primaryAction: UIAction { [weak self] _ in
            self?.saveTapped()
        })
        save.accessibilityIdentifier = "saveStudentButton"
        navigationItem.leftBarButtonItem = cancel
        navigationItem.rightBarButtonItem = save
    }

    private func setUpFields() {
        configure(nameField, label: "Name", placeholder: "Full name", identifier: "studentNameField")
        nameField.textContentType = .name
        nameField.autocapitalizationType = .words
        nameField.returnKeyType = .next
        nameField.addAction(UIAction { [weak self] _ in
            self?.ageField.becomeFirstResponder()
        }, for: .editingDidEndOnExit)

        configure(ageField, label: "Age", placeholder: "Age in years", identifier: "studentAgeField")
        ageField.keyboardType = .numberPad

        if case .edit(let id) = mode, let student = store.student(id: id) {
            nameField.text = student.name
            ageField.text = String(student.age)
        }
    }

    private func configure(_ field: UITextField, label: String, placeholder: String, identifier: String) {
        field.placeholder = placeholder
        field.accessibilityIdentifier = identifier
        field.accessibilityLabel = label
        field.font = .preferredFont(forTextStyle: .body)
        field.adjustsFontForContentSizeCategory = true
        field.borderStyle = .roundedRect
        field.clearButtonMode = .whileEditing
        field.autocorrectionType = .no
    }

    private func setUpLayout() {
        let stack = UIStackView(arrangedSubviews: [nameLabel, nameField, ageLabel, ageField])
        stack.axis = .vertical
        stack.spacing = 8
        stack.setCustomSpacing(20, after: nameField)

        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
        }
        [nameField, ageField].forEach { field in
            field.snp.makeConstraints { make in
                make.height.greaterThanOrEqualTo(44)
            }
        }
    }

    private static func makeLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.isAccessibilityElement = false
        return label
    }
}

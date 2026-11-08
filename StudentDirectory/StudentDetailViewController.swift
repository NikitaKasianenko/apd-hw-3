import SnapKit
import UIKit

/// Shows every field of one student. Only the student's id is kept; the
/// student itself is looked up in the shared store on every render.
final class StudentDetailViewController: UIViewController {
    let store: StudentStore
    let studentID: UUID

    let scrollView = UIScrollView()
    let avatarView = UIImageView()
    let nameLabel = StudentDetailViewController.makeLabel(style: .title1)
    let ageLabel = StudentDetailViewController.makeLabel(style: .body)
    let gradeLabel = StudentDetailViewController.makeLabel(style: .body)
    let scholarshipLabel = StudentDetailViewController.makeLabel(style: .body)
    let subjectsHeaderLabel = StudentDetailViewController.makeLabel(style: .headline)
    let subjectsStack = UIStackView()
    let idLabel = StudentDetailViewController.makeLabel(style: .footnote)
    let missingLabel = StudentDetailViewController.makeLabel(style: .body)
    private let contentStack = UIStackView()

    init(store: StudentStore, studentID: UUID) {
        self.store = store
        self.studentID = studentID
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// The student as currently stored, or `nil` if it was deleted.
    var student: Student? {
        store.student(id: studentID)
    }

    /// Subject buttons in the order of the student's `subjects`.
    var subjectButtons: [UIButton] {
        subjectsStack.arrangedSubviews.compactMap { $0 as? UIButton }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        let edit = UIBarButtonItem(systemItem: .edit, primaryAction: UIAction { [weak self] _ in
            self?.showEditForm()
        })
        edit.accessibilityIdentifier = "editStudentButton"
        edit.accessibilityLabel = "Edit student"
        navigationItem.rightBarButtonItem = edit
        setUpLayout()
        render()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        render()
    }

    func render() {
        guard let student else {
            title = nil
            navigationItem.rightBarButtonItem?.isEnabled = false
            contentStack.isHidden = true
            missingLabel.isHidden = false
            return
        }
        contentStack.isHidden = false
        missingLabel.isHidden = true
        navigationItem.rightBarButtonItem?.isEnabled = true

        title = student.name
        avatarView.image = UIImage(named: student.avatarName) ?? UIImage(named: "avatar-default")
        nameLabel.text = student.name
        ageLabel.text = StudentFormatting.age(student)
        gradeLabel.text = StudentFormatting.grade(student)
        scholarshipLabel.text = StudentFormatting.scholarship(student)
        subjectsHeaderLabel.text = student.subjects.isEmpty ? "Subjects: none" : "Subjects"
        idLabel.text = "Student ID: \(student.id.uuidString)"

        subjectsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for subject in student.subjects {
            subjectsStack.addArrangedSubview(makeSubjectButton(for: subject))
        }
    }

    private func makeSubjectButton(for subject: String) -> UIButton {
        var configuration = UIButton.Configuration.tinted()
        configuration.title = subject
        configuration.titleLineBreakMode = .byWordWrapping
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = UIFont.preferredFont(forTextStyle: .body)
            return attributes
        }
        let button = UIButton(configuration: configuration)
        button.contentHorizontalAlignment = .leading
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.accessibilityIdentifier = "subjectButton.\(subject)"
        button.accessibilityLabel = subject
        button.accessibilityHint = "Shows all students taking \(subject)"
        button.addAction(UIAction { [weak self] _ in
            self?.showStudents(taking: subject)
        }, for: .primaryActionTriggered)
        return button
    }

    func showEditForm() {
        let form = StudentFormViewController(store: store, mode: .edit(studentID))
        form.onSave = { [weak self] in
            self?.render()
        }
        present(UINavigationController(rootViewController: form), animated: true)
    }

    func showStudents(taking subject: String) {
        let list = StudentListViewController(store: store, mode: .subject(subject))
        navigationController?.pushViewController(list, animated: true)
    }

    private func setUpLayout() {
        scrollView.accessibilityIdentifier = "studentDetails"
        scrollView.alwaysBounceVertical = true

        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 48
        avatarView.backgroundColor = .secondarySystemBackground
        avatarView.isAccessibilityElement = false

        nameLabel.accessibilityTraits.insert(.header)
        subjectsHeaderLabel.accessibilityTraits.insert(.header)
        idLabel.textColor = .secondaryLabel

        subjectsStack.axis = .vertical
        subjectsStack.spacing = 8

        missingLabel.text = "This student is no longer in the directory."
        missingLabel.textAlignment = .center
        missingLabel.isHidden = true

        // The avatar keeps a fixed square size; its container stretches with the stack.
        let avatarContainer = UIView()
        avatarContainer.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            make.size.equalTo(96)
        }

        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.alignment = .fill
        [avatarContainer, nameLabel, ageLabel, gradeLabel, scholarshipLabel, subjectsHeaderLabel, subjectsStack, idLabel]
            .forEach(contentStack.addArrangedSubview)
        contentStack.setCustomSpacing(20, after: scholarshipLabel)
        contentStack.setCustomSpacing(20, after: subjectsStack)

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        scrollView.addSubview(missingLabel)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentStack.snp.makeConstraints { make in
            make.top.bottom.equalTo(scrollView.contentLayoutGuide).inset(20)
            make.leading.trailing.equalTo(scrollView.frameLayoutGuide).inset(20)
        }
        missingLabel.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).inset(40)
            make.leading.trailing.equalTo(scrollView.frameLayoutGuide).inset(20)
        }
    }

    private static func makeLabel(style: UIFont.TextStyle) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: style)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }
}

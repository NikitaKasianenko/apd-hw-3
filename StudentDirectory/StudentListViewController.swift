import SnapKit
import UIKit

/// Shows either every student or only the students taking one subject.
/// Rows are always read from the shared store; the controller keeps no copy.
final class StudentListViewController: UIViewController {
    enum Mode: Equatable {
        case all
        case subject(String)
    }

    let store: StudentStore
    let mode: Mode
    let tableView = UITableView(frame: .zero, style: .plain)

    init(store: StudentStore, mode: Mode = .all) {
        self.store = store
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
        switch mode {
        case .all:
            title = "Students"
        case .subject(let subject):
            title = subject
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// The rows currently shown, in store order.
    var visibleStudents: [Student] {
        switch mode {
        case .all:
            return store.students
        case .subject(let subject):
            return store.students(matchingSubject: subject)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        tableView.accessibilityIdentifier = "studentList"
        tableView.register(StudentCell.self, forCellReuseIdentifier: StudentCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        if mode == .all {
            let add = UIBarButtonItem(systemItem: .add, primaryAction: UIAction { [weak self] _ in
                self?.showAddForm()
            })
            add.accessibilityIdentifier = "addStudentButton"
            add.accessibilityLabel = "Add student"
            navigationItem.rightBarButtonItem = add
        }
    }

    func showAddForm() {
        let form = StudentFormViewController(store: store, mode: .add)
        form.onSave = { [weak self] in
            self?.studentWasAdded()
        }
        present(UINavigationController(rootViewController: form), animated: true)
    }

    /// Reloads from the store and reveals the new last row.
    func studentWasAdded() {
        tableView.reloadData()
        let count = visibleStudents.count
        guard count > 0 else { return }
        tableView.scrollToRow(at: IndexPath(row: count - 1, section: 0), at: .bottom, animated: false)
    }

    /// Deletes the student shown in `row` from the shared store.
    /// Returns `false` if nothing was deleted.
    @discardableResult
    func deleteStudent(atRow row: Int) -> Bool {
        let students = visibleStudents
        guard students.indices.contains(row) else { return false }
        do {
            try store.deleteStudent(id: students[row].id)
        } catch {
            tableView.reloadData()
            return false
        }
        tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
        return true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selected, animated: animated)
        }
        tableView.reloadData()
    }
}

extension StudentListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        visibleStudents.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: StudentCell.reuseIdentifier, for: indexPath)
        let students = visibleStudents
        if let studentCell = cell as? StudentCell, students.indices.contains(indexPath.row) {
            studentCell.configure(with: students[indexPath.row])
        }
        return cell
    }
}

extension StudentListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let students = visibleStudents
        guard students.indices.contains(indexPath.row) else { return }
        let details = StudentDetailViewController(store: store, studentID: students[indexPath.row].id)
        navigationController?.pushViewController(details, animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            completion(self?.deleteStudent(atRow: indexPath.row) ?? false)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

import SnapKit
import UIKit

/// Reusable row: avatar, name, age, average grade, and scholarship status.
/// The cell only displays the values it is given.
final class StudentCell: UITableViewCell {
    static let reuseIdentifier = "StudentCell"

    let avatarView = UIImageView()
    let nameLabel = StudentCell.makeLabel(style: .headline)
    let ageLabel = StudentCell.makeLabel(style: .subheadline)
    let gradeLabel = StudentCell.makeLabel(style: .subheadline)
    let scholarshipLabel = StudentCell.makeLabel(style: .subheadline)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        setUpLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func configure(with student: Student) {
        avatarView.image = UIImage(named: student.avatarName) ?? UIImage(named: "avatar-default")
        nameLabel.text = student.name
        ageLabel.text = StudentFormatting.age(student)
        gradeLabel.text = StudentFormatting.grade(student)
        scholarshipLabel.text = StudentFormatting.scholarship(student)
        accessibilityIdentifier = "studentCell.\(student.id.uuidString)"
        accessibilityLabel = StudentFormatting.summary(student)
    }

    private func setUpLayout() {
        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 28
        avatarView.backgroundColor = .secondarySystemBackground
        avatarView.isAccessibilityElement = false

        scholarshipLabel.textColor = .secondaryLabel
        gradeLabel.textColor = .secondaryLabel
        ageLabel.textColor = .secondaryLabel

        let textStack = UIStackView(arrangedSubviews: [nameLabel, ageLabel, gradeLabel, scholarshipLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        contentView.addSubview(avatarView)
        contentView.addSubview(textStack)

        avatarView.snp.makeConstraints { make in
            make.leading.equalTo(contentView.layoutMarginsGuide)
            make.top.equalTo(contentView.layoutMarginsGuide)
            make.bottom.lessThanOrEqualTo(contentView.layoutMarginsGuide)
            make.size.equalTo(56)
        }
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.trailing.equalTo(contentView.layoutMarginsGuide)
            make.top.bottom.equalTo(contentView.layoutMarginsGuide)
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

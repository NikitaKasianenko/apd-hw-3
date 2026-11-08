# HW3 Student Plan

## Approach

**MVC boundary.**

- *Model:* `Student` (unchanged) and `StudentStore`, the single source of truth for the student list,
  subject filtering, and the bonus add/edit/delete methods.
- *View:* `StudentCell` (reusable `UITableViewCell`: avatar, name, age, average grade, scholarship status)
  and the views built inside the detail screen. Views only display values they are given.
- *Controller:* `StudentListViewController` and `StudentDetailViewController`. Controllers read from the
  store, configure views, and handle navigation. They never keep their own copy of the students.

**One shared store.** `SceneDelegate` creates one `StudentStore` and passes the same instance through
initializers to every controller (dependency injection, no singletons, no global arrays).

- The list controller is reused for both lists through a mode: `.all` (title `Students`) or
  `.subject(String)` (title = the subject). It asks the store for rows every time it reloads:
  `store.students` or `store.students(matchingSubject:)`.
- The detail controller keeps only the student's `id` and looks the student up in the store, so it always
  shows current data.

**Subject filtering.** The detail screen shows one button per subject. Tapping a subject pushes a new
list controller in `.subject` mode. Filtering is the store's exact, case-sensitive `contains`, which
keeps store order.

**UI and accessibility.**

- All layout uses SnapKit.
- Text uses `preferredFont(forTextStyle:)`, `adjustsFontForContentSizeCategory = true`, and
  `numberOfLines = 0` for Dynamic Type.
- Required identifiers: `studentList`, `studentCell.<id>`, `studentDetails`, `subjectButton.<subject>`,
  plus `addStudentButton` and `editStudentButton` for the bonus.
- Each cell gets one combined accessibility label (name, age, grade, scholarship). Avatars are decorative.
- Text fields in the bonus form are read with `guard let` / `Int(...)`, no force unwraps.

**Bonus.** An add button in the main list and an edit button on the detail screen open a two-field form
(name, age) that calls the existing store methods and shows the validation error in an alert. Swipe to
delete calls `deleteStudent(id:)`. Lists and the detail screen reload from the store in `viewWillAppear`
and right after each successful mutation, so visible state is always fresh.

## Milestones

- [ ] Student list and reusable cell
- [ ] Detail screen and navigation
- [ ] Subject-filtered list
- [ ] Unit and UI tests
- [ ] Optional add/edit/delete bonus, if attempted
- [ ] Local verification and CI review
- [ ] Final diff and evidence review

## Verification plan

Focused runs while working:

```bash
xcodebuild -project StudentDirectory.xcodeproj -scheme StudentDirectory -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:StudentDirectoryTests
xcodebuild -project StudentDirectory.xcodeproj -scheme StudentDirectory -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:StudentDirectoryUITests
```

Planned student tests (at least six, model/store and UI):

- Store: filtering is exact and case-sensitive (`"Math"` returns Ada, Katherine, Donald in store order;
  `"math"` returns nothing).
- Store: invalid input and unknown IDs do not change the students (bonus methods).
- Store: a new student gets grade `0`, no scholarship, no subjects, and the default avatar.
- Controller: the main list shows 10 rows and the title `Students`; subject mode shows only matching rows.
- UI: tapping `studentCell.<id>` opens `studentDetails` with that student's fields.
- UI: tapping `subjectButton.Math` opens a list titled `Math` with exactly the matching cells, and Back
  returns to the details screen.

The UI tests rely on the fixed seed data and accessibility identifiers only, with no sleeps or timing
checks. Each launch starts with a fresh in-memory store.

Final command, as in the README:

```bash
xcodebuild -project StudentDirectory.xcodeproj -scheme StudentDirectory -destination 'platform=iOS Simulator,name=iPhone 17' test
```

The local result and the GitHub Actions run URL and status are recorded in `AGENT_WORKLOG.md`.

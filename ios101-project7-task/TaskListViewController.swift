//
//  TaskListViewController.swift
//

import UIKit

class TaskListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    // An "Empty State" label to show when there aren't any tasks.
    @IBOutlet weak var emptyStateLabel: UILabel!

    // The main tasks array initialized with a default value of an empty array.
    var tasks = [Task]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Hide top cell separator
        tableView.tableHeaderView = UIView()

        // Set table view data source
        tableView.dataSource = self

        // Set table view delegate
        tableView.delegate = self
    }

    // Refresh the tasks list each time the view appears in case any tasks were updated on the other tab.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshTasks()
    }

    // "+" button tapped → segue to Compose
    @IBAction func didTapNewTaskButton(_ sender: Any) {
        performSegue(withIdentifier: "ComposeSegue", sender: nil)
    }

    // Prepare for navigation to Task Compose View Controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ComposeSegue" {
            if let composeNavController = segue.destination as? UINavigationController,
               let composeViewController = composeNavController.topViewController as? TaskComposeViewController {

                composeViewController.taskToEdit = sender as? Task

                composeViewController.onComposeTask = { [weak self] task in
                    task.save()              // ✅ 用 save() 存回本地
                    self?.refreshTasks()
                }
            }
        }
    }

    // MARK: - Helper Functions
    
    private func refreshTasks() {
        var tasks = Task.getTasks()
        tasks.sort { lhs, rhs in
            if lhs.isComplete && rhs.isComplete {
                return (lhs.completedDate ?? .distantPast) < (rhs.completedDate ?? .distantPast)
            } else if !lhs.isComplete && !rhs.isComplete {
                return lhs.createdDate < rhs.createdDate
            } else {
                return !lhs.isComplete && rhs.isComplete
            }
        }
        self.tasks = tasks
        emptyStateLabel.isHidden = !tasks.isEmpty
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
}

// MARK: - Table View Data Source
extension TaskListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskCell
        let task = tasks[indexPath.row]
        cell.configure(with: task, onCompleteButtonTapped: { [weak self] toggledTask in
            toggledTask.save()    // ✅ 切換完成狀態後也用 save()
            self?.refreshTasks()
        })
        return cell
    }

    // Swipe to Delete
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tasks.remove(at: indexPath.row)
            Task.save(tasks)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}

// MARK: - Table View Delegate
extension TaskListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let selectedTask = tasks[indexPath.row]
        performSegue(withIdentifier: "ComposeSegue", sender: selectedTask)
    }
}


//
//  TaskListViewController.swift
//  HalgoraeDO
//
//  Created by woong on 2020/11/23.
//

import UIKit

class TaskListViewController: UIViewController {
    
    private var interactor: TaskListBusinessLogic?
    private var router: (TaskListRoutingLogic & TaskListDataPassing)?
    // MARK:  - Constants
    
    typealias TaskVM = TaskListModels.TaskVM
    
    // MARK: - Properties
    
    private var project: Project
    private var generator = TaskListGenerator()
    private var dataSource: UICollectionViewDiffableDataSource<TaskListModels.SectionVM, TaskVM>! = nil
    private var shouldDisplayDoneTasks = false
    private var presentConfirmActionWorkItem: DispatchWorkItem?
    private var childCheck = 0
    private var startIndex: IndexPath?
    private var startPoint: CGPoint?
    private(set) var selectedTasks = Set<TaskVM>() {
        didSet {
            guard isEditing else { return }
            title = "\(selectedTasks.count) 개 선택됨"
        }
    }
    
    // MARK: Views
    
    @IBOutlet weak private var taskListCollectionView: UICollectionView!
    @IBOutlet weak private var moreButton: UIBarButtonItem!
    @IBOutlet weak private var editToolBar: UIToolbar!
    @IBOutlet weak private var confirmActionView: ConfirmActionView!
    private var lineView = LineView()
    private var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .halgoraedoMint
        refreshControl.addTarget(self, action: #selector(didChangeRefersh(_:)), for: .valueChanged)
        
        return refreshControl
    }()

    // MARK: - View Life Cycle
    
    init?(coder: NSCoder, project: Project) {
        self.project = project
        super.init(coder: coder)
        title = project.title
    }
    
    required init?(coder: NSCoder) {
        self.project = Project(context: Storage().childContext)
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        configureDataSource()
        configureLogic()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        interactor?.fetchTasks(request: .init(projectId: project.id))
    }
    
    // MARK: - Initialize
    
    private func configureCollectionView() {
        taskListCollectionView.collectionViewLayout = generator.configureLayout(leadingSwipeAction: editAction(at:))
        taskListCollectionView.allowsMultipleSelectionDuringEditing = true
        taskListCollectionView.dragInteractionEnabled = true
        taskListCollectionView.refreshControl = refreshControl
    }
    
    private func configureDataSource() {
        let cellRegistration = generator.registration.normal { [weak self] cell, taskVM in
            guard let self = self else { return }
            self.showCofirmToastAndDismiss { [weak self] in
                var cancelTask = taskVM
                cancelTask.isCompleted = !cancelTask.isCompleted
                cell?.taskViewModel = cancelTask
                self?.interactor?.updateComplete(request: .init(displayedTasks: [cancelTask]))
                self?.confirmActionView.isHidden = true
            }
            self.interactor?.updateComplete(request: .init(displayedTasks: [taskVM]))
        }

        dataSource = UICollectionViewDiffableDataSource<TaskListModels.SectionVM, TaskVM>(collectionView: taskListCollectionView, cellProvider: { (collectionView, indexPath, task) -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: task)
        })
        
        dataSource.supplementaryViewProvider = { [weak self] (view, kind, index) in
            guard let self = self else { return nil }
            let sections = self.dataSource.snapshot().sectionIdentifiers
            return self.taskListCollectionView.dequeueConfiguredReusableSupplementary(using: self.generator.registration.header(sections: sections), for: index)
        }
    }
    
    private func configureLogic() {
        let presenter = TaskListPresenter(viewController: self)
        let interactor = TaskListInteractor(presenter: presenter,
                                            worker: TaskListWorker(sessionManager: SessionManager(configuration: .default)))
        self.interactor = interactor
        router = TaskListRouter(listViewController: self, dataStore: interactor)
    }
    
    // MARK: - Methods
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        set(editingMode: editing)
    }
    
    private func set(editingMode: Bool) {
        if !editingMode {
            editToolBar.items?.removeLast()
            selectedTasks.removeAll()
        } else {
            let allCheckToolBarItem = UIBarButtonItem(title: "작업 완료", style: .plain, target: self, action: #selector(tapAllCheckToolBarItem(_:)))
            editToolBar.items?.append(allCheckToolBarItem)
        }
        title = editingMode ? "\(selectedTasks.count) 개 선택됨" : project.title
        taskListCollectionView.isEditing = editingMode
        moreButton.title = editingMode ? "취소" : "More"
    }
    
    private func showCofirmToastAndDismiss(backHandler: (() -> Void)?) {
        confirmActionView.slideRight()
        confirmActionView.backHandler = backHandler
        
        presentConfirmActionWorkItem?.cancel()
        presentConfirmActionWorkItem = DispatchWorkItem { self.confirmActionView.isHidden = true }
        if let workItem = presentConfirmActionWorkItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
        }
    }
    
    private func editAction(at indexPath: IndexPath) -> UIContextualAction {
        return UIContextualAction(style: .normal, title: "Edit") { [weak self] (action, view, completion) in
            guard let self = self else { return }
            if !self.isEditing {
                self.setEditing(true, animated: true)
            }

            let section = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
            let taskItem = self.dataSource.snapshot(for: section).items[indexPath.row]
            self.selectedTasks.insert(taskItem)
            self.taskListCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .init())
        }
    }
    
    // MARK: Selectors
    
    @objc private func tapAllCheckToolBarItem(_ sender: UIBarButtonItem) {
        var selectItemTemp: [TaskVM] = []
        for selectedItem in selectedTasks {
            var tempSelectItem = selectedItem
            tempSelectItem.isCompleted = true
            selectItemTemp.append(tempSelectItem)
        }
        selectedTasks.removeAll()
        set(editingMode: false)
        
        self.interactor?.updateCompleteAll(request: .init(displayedTasks: selectItemTemp), projectId: project.id)
    }
    
    @objc private func didChangeRefersh(_ sender: UIRefreshControl) {
        interactor?.fetchTasks(request: .init(projectId: project.id))
        DispatchQueue.main.async {
            sender.endRefreshing()
        }
    }
    
    // MARK: IBActions
    
    @IBAction private func didTapMoreButton(_ sender: UIBarButtonItem) {
        let alert = SimpleAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.configureActions([
            UIAlertAction(title: "보드로 보기", style: .default, handler: { _ in
                self.router?.routeToBoard(project: self.project)
            }),
            UIAlertAction(title: "섹션 추가", style: .default, handler: { _ in
                self.addSectionAlert()
            }),
            UIAlertAction(title: "작업 선택", style: .default, handler: { _ in
                self.setEditing(true, animated: true)
            }),
            UIAlertAction(title: shouldDisplayDoneTasks ? "완료된 항목 숨기기" : "완료된 항목 보기", style: .default, handler: { _ in
                self.shouldDisplayDoneTasks.toggle()
                if self.shouldDisplayDoneTasks{
                    self.interactor?.fetchTasksForComplete(request: .init(projectId: self.project.id))
                } else {
                    self.interactor?.fetchTasks(request: .init(projectId: self.project.id))
                }
            }),
            UIAlertAction(title: "취소", style: .cancel, handler: nil)
        ])
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction private func didTapAddButton(_ sender: UIButton) {
        let taskAddViewController = TaskAddViewController()
        taskAddViewController.modalPresentationStyle = .overCurrentContext
        taskAddViewController.delegate = self
        present(taskAddViewController, animated: false, completion: nil)
    }
    
    private func addSectionAlert() {
        let alert = SimpleAlertController(title: "섹션 추가", message: "예. 3주차 할일", preferredStyle: .alert)
        alert.configureActions([
            UIAlertAction(title: "OK", style: .default) { (ok) in
                guard let sectionName = alert.textFields?[0].text,
                      sectionName != ""
                else { return }
                let sectionFields = TaskListModels.SectionFields(title: sectionName)
                self.interactor?.createSection(request: .init(projectId: self.project.id, sectionFields: sectionFields))
            },
            UIAlertAction(title: "cancel", style: .cancel)
        ])
        alert.addTextField { (textField) in
            textField.placeholder = "섹션 이름을 입력해주세요."
        }

        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - TaskList Display Logic

extension TaskListViewController: TaskListDisplayLogic {
    
    func displayFinishDragDrop(viewModel: TaskListModels.DragDropTask.ViewModel) {
        guard let snapshot = viewModel.snapshot,
              let sectionVM = viewModel.sectionVM
        else { return }
        
        dataSource.apply(snapshot, to: sectionVM)
    }
    
    func displayFetchTasks(viewModel: TaskListModels.FetchTasks.ViewModel) {
        DispatchQueue.main.async {
            self.dataSource.apply(viewModel.snapshot, to: viewModel.sectionVM, animatingDifferences: false)
        }
    }
    
    func displayFinishChanged(viewModel: TaskListModels.FinishTask.ViewModel) {
        guard !shouldDisplayDoneTasks else { return }
        var currentSnapshot = dataSource.snapshot()
        let completedTasks = viewModel.displayedTasks.filter { $0.isCompleted }
        currentSnapshot.deleteItems(completedTasks)
        dataSource.apply(currentSnapshot)
    }
}

// MARK:  - UICollectionView Delegate

extension TaskListViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = dataSource.snapshot().sectionIdentifiers[indexPath.section]
        let taskItem = dataSource.snapshot(for: section).items[indexPath.row]
  
        guard !isEditing else {
            selectedTasks.insert(taskItem)
            return
        }
        collectionView.deselectItem(at: indexPath, animated: true)
        let taskVM = dataSource.snapshot(for: dataSource.snapshot().sectionIdentifiers[indexPath.section]).items[indexPath.row]
        router?.routeToTaskDetail(for: taskVM, at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let taskVM = dataSource.snapshot().itemIdentifiers[indexPath.item]
        guard !isEditing else {
            selectedTasks.remove(taskVM)
            return
        }
    }
}

// MARK: - UICollectionViewDragDelegate

extension TaskListViewController: UICollectionViewDragDelegate {
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        startPoint = session.location(in: collectionView)
        collectionView.performUsingPresentationValues {
            startIndex = collectionView.indexPathForItem(at: session.location(in: collectionView))
        }
        if let cell = collectionView.cellForItem(at: indexPath) as? TaskCollectionViewListCell{
            let section = dataSource.snapshot().sectionIdentifiers[indexPath.section]
            var currentSnapshot = dataSource.snapshot(for: section)
            for item in currentSnapshot.items {
                if item.id == cell.taskViewModel?.id {
                    currentSnapshot.collapse([item])
                }
            }
            dataSource.apply(currentSnapshot, to: section, animatingDifferences: true)
        }
        
        return dragItems(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(at: indexPath)
    }
    
    private func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
        guard let taskObject = taskListCollectionView.cellForItem(at: indexPath) as? TaskCollectionViewListCell else { return [] }
        let provider = NSItemProvider(object: taskObject.taskViewModel!.id as NSString)
        let dragItem = UIDragItem(itemProvider: provider)
        guard let collectionView = taskListCollectionView else { return [dragItem] }
        let cell = collectionView.cellForItem(at: indexPath)
        dragItem.localObject = cell
        
        return [dragItem]
    }
}

// MARK: - UICollectionViewDropDelegate

extension TaskListViewController: UICollectionViewDropDelegate {
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        lineView.removeFromSuperview()
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let location = session.location(in: collectionView)
        var correctDestination: IndexPath?
        collectionView.performUsingPresentationValues {
            correctDestination = collectionView.indexPathForItem(at: location)
        }
        guard let destination = correctDestination else {
            return UICollectionViewDropProposal(
                operation: .cancel, intent: .unspecified
            )
        }
        
        return UICollectionViewDropProposal(operation: setLocation(session.location(in: collectionView), destination) ? .move : .forbidden, intent: .insertAtDestinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        lineView.removeFromSuperview()
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        for item in coordinator.items {
            guard let sourceIndexPath = item.sourceIndexPath,
                  ((item.dragItem.localObject as? TaskCollectionViewListCell) != nil)
            else {
                return
            }
            var tempDestinationIndex: IndexPath
            if destinationIndexPath.section == sourceIndexPath.section && destinationIndexPath.row > sourceIndexPath.row {
                tempDestinationIndex = IndexPath(row: destinationIndexPath.row, section: destinationIndexPath.section)
            } else {
                tempDestinationIndex = IndexPath(row: destinationIndexPath.row - 1, section: destinationIndexPath.section)
            }
            
            let destinationCell = collectionView.cellForItem(at: tempDestinationIndex) as? TaskCollectionViewListCell
            interactor?.dragDropForList(requset: .init(projectId: project.id, sourceIndexPath: sourceIndexPath, destinationIndexPath: tempDestinationIndex, childCheck: childCheck, dataSource: dataSource, destinationCell: destinationCell))
            coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
        }
    }
}

// MARK: - TaskAddViewController Delegate

extension TaskListViewController: TaskAddViewControllerDelegate {
    
    func taskAddViewControllerDidDone(_ taskAddViewController: TaskAddViewController) {
        guard dataSource.snapshot().sectionIdentifiers.count != 0 else { return }
        let projectId = project.id
        let sectionId = dataSource.snapshot().sectionIdentifiers[0].id
        let taskFields = TaskListModels.TaskFields(title: taskAddViewController.text,
                                                  date: taskAddViewController.date,
                                                  priority: "\(taskAddViewController.priority.rawValue)")
    
        interactor?.createTask(request: .init(projectId: projectId, sectionId: sectionId, taskFields: taskFields))
        taskAddViewController.dismiss(animated: false, completion: nil)
    }
}


private extension TaskListViewController {
    
    func setLocation(_ location: CGPoint, _ destination: IndexPath) -> Bool {
        lineView.removeFromSuperview()
        guard let startIndex = startIndex,
              let startPoint = startPoint,
              let collectionView = taskListCollectionView
        else { return false }
        
        if destination.row == 0 { return true }
        
        var tempDestinationIndex: IndexPath
        if destination.section == startIndex.section && destination.row > startIndex.row {
            tempDestinationIndex = IndexPath(row: destination.row, section: destination.section)
        } else {
            tempDestinationIndex = IndexPath(row: destination.row - 1, section: destination.section)
        }
        
        if startPoint.x <= location.x - 50 {
            childCheck = 1
        } else {
            childCheck = 0
        }
        
        guard let sourceTask = (collectionView.cellForItem(at: startIndex) as? TaskCollectionViewListCell)?.taskViewModel,
              let destinationCell = collectionView.cellForItem(at: tempDestinationIndex) as? TaskCollectionViewListCell
        else { return false }
        
        if destinationCell.indentationLevel == 1 {
            childCheck = 0
            if sourceTask.subItems.count != 0 {
                return false
            }
        } else if childCheck == 1 && sourceTask.subItems.count != 0 {
            return false
        }
        
        let cellDepth = destinationCell.indentationWidth * CGFloat(destinationCell.indentationLevel)
        let childDepth = CGFloat(childCheck) * destinationCell.indentationWidth
        drawLineView(cellDepth + childDepth, destinationCell)
        
        return true
    }
    
    func drawLineView(_ depthWidth: CGFloat, _ cell: TaskCollectionViewListCell) {
        lineView.frame = CGRect(x: 10 + depthWidth, y: cell.frame.height - 2, width: cell.frame.width - depthWidth - 20, height: 5)
        cell.addSubview(lineView)
    }
}


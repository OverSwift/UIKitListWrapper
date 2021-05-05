//
//  UIList.swift
//  CustomViews
//
//  Created by Sergiy Loza on 16.01.2021.
//

import Foundation
import UIKit
import SwiftUI
import Combine

public protocol ItemsSection: Hashable {
    
    associatedtype Element
    
    var items: [Element] { get }
}

extension UIList where Fotter == Never {
    
    public init(data: [Section],
                itemConfig: @escaping ConfigBlock,
                header: HeaderBlock? = nil) {
        self.configBlock = itemConfig
        self.header = header
        self.data = data
        self.contentInsets = .zero
    }
}

extension UIList where Header == Never {
    
    public init(data: [Section],
                itemConfig: @escaping ConfigBlock,
                fotter: FotterBlock? = nil) {
        self.configBlock = itemConfig
        self.fotter = fotter
        self.data = data
        self.contentInsets = .zero
    }
}

extension UIList where Header == Never, Fotter == Never {
    
    public init(data: [Section],
                itemConfig: @escaping ConfigBlock
                ) {
        self.configBlock = itemConfig
        self.data = data
        self.contentInsets = .zero
    }
}

public class TableController: UIViewController {
    
    let tableView: UITableView = {
        let view = UITableView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

public struct UIList<Section, Item, Content, Header, Fotter>: UIViewControllerRepresentable where
    Section:ItemsSection,
    Item: Hashable,
    Section.Element == Item,
    Content: View,
    Header: View,
    Fotter: View {
    
    public typealias ConfigBlock = (Item) -> Content
    public typealias HeaderBlock = (Section, Int) -> Header
    public typealias FotterBlock = (Section, Int) -> Fotter
    
    public init(data: [Section],
                itemConfig: @escaping ConfigBlock,
                header: HeaderBlock? = nil,
                fotter: FotterBlock? = nil) {
        self.configBlock = itemConfig
        self.header = header
        self.fotter = fotter
        self.data = data
        self.contentInsets = .zero
    }
    
    var data: [Section]
    var configBlock: ConfigBlock
    var header: HeaderBlock?
    var fotter: FotterBlock?
    var animateChanges: Bool = false
    var contentInsets: UIEdgeInsets = .zero
    
    var onCellAppear: ((Content) -> Void)?
    var onCellDissappear: ((Content) -> Void)?
    
    private var vc: TableController = {
        let controller = TableController()
        controller.tableView.register(HostTableViewCell<Content>.self, forCellReuseIdentifier: "Cell")
        controller.tableView.register(HostTableViewHeaderFotterView<Header>.self, forHeaderFooterViewReuseIdentifier: "Header")
        controller.tableView.register(HostTableViewHeaderFotterView<Fotter>.self, forHeaderFooterViewReuseIdentifier: "Fotter")
        controller.tableView.separatorColor = .clear
        controller.tableView.separatorStyle = .none
        return controller
    } ()
    
    public func makeUIViewController(context: Context) -> TableController {
        vc.tableView.contentInset = self.contentInsets
        return vc
    }
    
    public func updateUIViewController(_ pageViewController: TableController, context: Context) {
        context.coordinator.fresh = fresh
        context.coordinator.data = data.map { $0 }
    }
    
    public func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(self)
        vc.tableView.delegate = coordinator
        vc.tableView.prefetchDataSource = coordinator
        return coordinator
    }
    
    public func contentInsets(_ insets: UIEdgeInsets) -> Self {
        var copy = self
        copy.contentInsets = insets
        return copy
    }
    
    public func animateTableChanges(_ animate: Bool) -> Self {
        var copy = self
        copy.animateChanges = animate
        return copy
    }
    
    private var fresh: Bool = true
    
    public func setFresh(_ fresh: Bool) -> Self {
        var copy = self
        copy.fresh = fresh
        return copy
    }
    
    public func fotter(_ block: FotterBlock?) -> Self {
        var new = self
        new.fotter = block
        return self
    }

    public func header(_ block: HeaderBlock?) -> Self {
        var new = self
        new.header = block
        return self
    }
    
    public class Coordinator: NSObject, UITableViewDelegate, UITableViewDataSourcePrefetching {
        
        typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
        
        var tableController: TableController {
            parent.vc
        }
        
        private var dataSource: UITableViewDiffableDataSource<Section, Item>?
        
        var parent: UIList
        
        var fresh: Bool = true
        
        var data: [Section] = [] {
            didSet {
                update(with: data)
            }
        }
        
        private var dataUpdateQueue: DispatchQueue = DispatchQueue(label: "com.list.data.update.queue")
        
        deinit {
            data.removeAll()
        }
        
        init(_ parent: UIList) {
            self.parent = parent
            super.init()
            createDataSource()
        }
        
        private func createDataSource() {
            let table = tableController.tableView
            self.dataSource = UITableViewDiffableDataSource<Section, Item>(tableView: table) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? HostTableViewCell<Content> else { return nil }
                guard let self = self else { return nil }
                cell.setView(self.parent.configBlock(item), parentController: self.tableController)
                return cell
            }
            dataSource?.defaultRowAnimation = .fade
        }
        
        private var lastUpdatedIds:[Item] = []
        
        fileprivate func update(with data: [Section]) {
            dataUpdateQueue.async { [weak self] in
                var snapshot = Snapshot()
                snapshot.appendSections(data)
                
                data.forEach { (section) in
                    snapshot.appendItems(section.items, toSection: section)
                }
                
                guard let self = self else { return }
                
                let current = self.dataSource?.snapshot()
                if let ids = current?.itemIdentifiers  {
                    let new = snapshot.itemIdentifiers
                    if !new.isEmpty && new == self.lastUpdatedIds {
                        return
                    }
                    if ids == new {
                        DispatchQueue.main.async {
                            self.tableController.tableView.beginUpdates()
                            self.tableController.tableView.endUpdates()
                            self.lastUpdatedIds = new
                        }
                        return
                    }
                }
                self.dataSource?.apply(snapshot, animatingDifferences: self.parent.animateChanges) { [weak self] in
                    guard let self = self else { return }
                    guard self.tableController.tableView.numberOfSections > 0 else { return }
                    if self.fresh {
                        self.tableController.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                    }
                }
            }
        }
        
        public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//            guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? HostTableViewCell<Content> else { return }
//            guard let item = dataSource?.itemIdentifier(for: indexPath) else { return }
//            print("Will display item \(item)")
        }
        
        public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
            
        }
        
        public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
            indexPaths.forEach { indexPath in
                if indexPath.section == data.count - 1 {
                    if indexPath.row == data[indexPath.section].items.count - 1 {
                        print("=== DISPLAY LAST ITEM IN TABLE REQUEST MORE !!! ===")
                    }
                }
            }
        }
        
        public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            guard (self.parent.header != nil) else {
                return 0
            }
            return UITableView.automaticDimension
        }

        public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
            guard let block = self.parent.header else {
                return nil
            }
            
            guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Header") as? HostTableViewHeaderFotterView<Header> else { return nil }
            let item = data[section]
            
            view.setView(block(item, section), parentController: self.tableController)
            view.setNeedsLayout()
            return view
        }
        
        public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
            guard (self.parent.fotter != nil) else {
                return 0
            }
            return UITableView.automaticDimension
        }
        
        public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
            guard let block = self.parent.fotter else {
                return nil
            }
            
            guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Fotter") as? HostTableViewHeaderFotterView<Fotter> else { return nil }
            let item = data[section]
            
            view.setView(block(item, section), parentController: self.tableController)
            return view
        }
    }
}

fileprivate class ListSection<T>: Identifiable, ItemsSection where T: Hashable {
    
    let title: String
    
    var items: [T] = []
    
    init(title: String) {
        self.title = title
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(items)
    }
}

extension ListSection: Hashable {
    
    static func == (lhs: ListSection<T>, rhs: ListSection<T>) -> Bool {
        return lhs.title == rhs.title && lhs.items == rhs.items
    }
}

struct UIList_Previews: PreviewProvider {
    
    private static let data:[ListSection<String>] = {
        let section = ListSection<String>(title: "Test")
        
        section.items.append("One")
        section.items.append("Two")
        section.items.append("Three")
        
        return [section]
    }()
    
    static var previews: some View {
        Text("")
    }
}

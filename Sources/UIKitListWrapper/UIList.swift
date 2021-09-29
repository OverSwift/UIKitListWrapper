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

public struct AAAcition: Equatable {
    
    public var title: String
    
    static let empty = AAAcition(title: "none")
    
    public init(title: String) {
        self.title = title
    }
}


//UIContextMenuConfiguration

struct ContextMenuPreferenceKey: PreferenceKey {
    
    static var defaultValue: UIContextMenuConfiguration? = nil
    
    static func reduce(value: inout UIContextMenuConfiguration?, nextValue: () -> UIContextMenuConfiguration?) {
        value = nextValue()
    }
}

extension View {
    public func setUIListContextMenu(_ menu: UIContextMenuConfiguration) -> some View {
        self.preference(key: ContextMenuPreferenceKey.self, value: menu)
    }
}


struct TrailActionsPreferenceKey: PreferenceKey {
    
    public static var defaultValue: UISwipeActionsConfiguration? = nil
    
    public static func reduce(value: inout UISwipeActionsConfiguration?, nextValue: () -> UISwipeActionsConfiguration?) {
        value = nextValue()
    }
}

struct LeadingActionsPreferenceKey: PreferenceKey {
    
    public static var defaultValue: UISwipeActionsConfiguration? = nil
    
    public static func reduce(value: inout UISwipeActionsConfiguration?, nextValue: () -> UISwipeActionsConfiguration?) {
        value = nextValue()
    }
}

extension View {
    
    public func uilistTrailingActions(_ action: UISwipeActionsConfiguration?) -> some View {
        self.preference(key: TrailActionsPreferenceKey.self, value: action)
    }
    
    public func uilistLeadingActionsAction(_ action: UISwipeActionsConfiguration?) -> some View {
        self.preference(key: TrailActionsPreferenceKey.self, value: action)
    }
}

struct CellContentWrapper<Content: View>: View {
    
    var content: () -> Content
    
    var onTrailingActions: (UISwipeActionsConfiguration) -> Void
    var onLeadingActions: (UISwipeActionsConfiguration) -> Void
    var contextMenu: (UIContextMenuConfiguration) -> Void
    
    var body: some View {
        content()
            .onPreferenceChange(TrailActionsPreferenceKey.self, perform: { value in
                if let actions = value {
                    onTrailingActions(actions)
                }
            })
            .onPreferenceChange(ContextMenuPreferenceKey.self, perform: { value in
                if let menu = value {
                    self.contextMenu(menu)
                }
            })
            .onPreferenceChange(LeadingActionsPreferenceKey.self, perform: { value in
                if let actions = value {
                    onLeadingActions(actions)
                }
            })
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
    
    private var onRefresh: (() -> Void)?    
    private var trailingActions: ((Item) -> UISwipeActionsConfiguration?)?
    private var leadingActions: ((Item) -> UISwipeActionsConfiguration?)?

    private var tableController: TableController = {
        let controller = TableController()
        controller.tableView.register(HostTableViewCell<CellContentWrapper<Content>>.self, forCellReuseIdentifier: "Cell")
        controller.tableView.register(HostTableViewHeaderFotterView<Header>.self, forHeaderFooterViewReuseIdentifier: "Header")
        controller.tableView.register(HostTableViewHeaderFotterView<Fotter>.self, forHeaderFooterViewReuseIdentifier: "Fotter")
        controller.tableView.separatorColor = .clear
        controller.tableView.separatorStyle = .none
        return controller
    } ()
    
    public func makeUIViewController(context: Context) -> TableController {
        tableController.tableView.contentInset = self.contentInsets
        context.coordinator.configBlock = configBlock
        context.coordinator.header = header
        context.coordinator.fotter = fotter
        context.coordinator.animateChanges = self.animateChanges
        return tableController
    }
    
    public func updateUIViewController(_ tableViewController: TableController, context: Context) {
        context.coordinator.fresh = fresh
        context.coordinator.configBlock = configBlock
        context.coordinator.header = header
        context.coordinator.fotter = fotter
        context.coordinator.animateChanges = self.animateChanges
        context.coordinator.data = data.map { $0 }
        tableViewController.tableView.contentInset = self.contentInsets
        tableViewController.tableView.scrollIndicatorInsets = self.contentInsets        
        if let ref = onRefresh {
            context.coordinator.tableController?.addPullToRefresh {
                ref()
            }
        }
    }
    
    public static func dismantleUIViewController(_ uiViewController: TableController, coordinator: Coordinator) {
        coordinator.clear()
    }
    
    public func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(tableController: tableController, configBlock: configBlock, header: header, fotter: fotter, animateChanges: self.animateChanges)
        tableController.tableView.delegate = coordinator
        tableController.tableView.prefetchDataSource = coordinator
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
        return new
    }

    public func header(_ block: HeaderBlock?) -> Self {
        var new = self
        new.header = block
        return new
    }
    
    public func setPullToRefresh(_ block: @escaping () -> Void) -> Self {
        var new = self
        new.onRefresh = block
        return new
    }
            
    public class Coordinator: NSObject, UITableViewDelegate, UITableViewDataSourcePrefetching {
        
        typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
        
        weak var tableController: TableController?
        
        private var dataSource: UITableViewDiffableDataSource<Section, Item>?
        private var dataUpdateQueue: DispatchQueue = DispatchQueue(label: "com.list.data.update.queue")
        
        var fresh: Bool = true
        var animateChanges: Bool
        
        var data: [Section] = [] {
            didSet {
                update(with: data)
            }
        }
        private var lastUpdatedIds:[Item] = []
        var configBlock: ConfigBlock
        var header: HeaderBlock?
        var fotter: FotterBlock?

        init(tableController: TableController,
             configBlock: @escaping ConfigBlock,
             header: HeaderBlock?,
             fotter: FotterBlock?,
             animateChanges: Bool) {
            self.tableController = tableController
            self.configBlock = configBlock
            self.header = header
            self.fotter = fotter
            self.animateChanges = animateChanges
            super.init()
            createDataSource()
        }
        
        func clear() {
            dataSource = nil
            lastUpdatedIds.removeAll()
            data.removeAll()
            tableController = nil
        }
        
        deinit {
            lastUpdatedIds.removeAll()
            data.removeAll()
        }
        
        private var trailingActions: [IndexPath : UISwipeActionsConfiguration] = [:]
        private var leadingActions: [IndexPath : UISwipeActionsConfiguration] = [:]
        private var menuActions: [IndexPath : UIContextMenuConfiguration] = [:]

        private func createDataSource() {
            guard let table = tableController?.tableView else { return }
            self.dataSource = InternalDataSource<Section, Item>(tableView: table) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? HostTableViewCell<CellContentWrapper<Content>> else { return nil }
                guard let self = self else { return nil }
                let view = self.configBlock(item)
                
                let wrapped = CellContentWrapper {
                    view
                } onTrailingActions: { [weak self] (trailing) in
                    self?.trailingActions[indexPath] = trailing
                } onLeadingActions: { (leading) in
                    self.leadingActions[indexPath] = leading
                } contextMenu: { [weak self] (menu) in
                    self?.menuActions[indexPath] = menu
                }
                if let tableController = self.tableController {
                    cell.setView(wrapped, parentController: tableController)
                }
                return cell
            }
            dataSource?.defaultRowAnimation = .fade
        }
        
        
        
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
                        self.refreshTableSizes()
                        return
                    }
                    if ids == new {
                        DispatchQueue.main.async {
                            self.lastUpdatedIds = new
                        }
                        self.refreshTableSizes()
                        return
                    }
                }
                self.dataSource?.apply(snapshot, animatingDifferences: self.animateChanges) { [weak self] in
                    guard let self = self else { return }
                    self.tableController?.tableView.refreshControl?.endRefreshing()
                    guard self.tableController?.tableView.numberOfSections ?? 0 > 0 else { return }
                    DispatchQueue.main.async {
                        self.lastUpdatedIds = snapshot.itemIdentifiers
                    }
                    if self.fresh {
                        self.tableController?.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                    }
                }
            }
        }
        
        private func refreshTableSizes() {
            DispatchQueue.main.async {
                self.tableController?.tableView.beginUpdates()
                self.tableController?.tableView.endUpdates()
                self.tableController?.tableView.refreshControl?.endRefreshing()
            }
        }
        
        public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        }
        
        public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
            
        }
        
        public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
            indexPaths.forEach { indexPath in
                if indexPath.section == data.count - 1 {
                    if indexPath.row == data[indexPath.section].items.count - 1 {
                    }
                }
            }
        }
        
        public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            guard (self.header != nil) else {
                return 0
            }
            return UITableView.automaticDimension
        }

        public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
            guard let block = self.header else {
                return nil
            }
            
            guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Header") as? HostTableViewHeaderFotterView<Header> else { return nil }
            let item = data[section]
            
            if let tableController = self.tableController {
                view.setView(block(item, section), parentController: tableController)
            }
            
            view.setNeedsLayout()
            return view
        }
        
        public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
            guard (self.fotter != nil) else {
                return 0
            }
            return UITableView.automaticDimension
        }
        
        public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
            guard let block = self.fotter else {
                return nil
            }
            
            guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Fotter") as? HostTableViewHeaderFotterView<Fotter> else { return nil }
            let item = data[section]
            if let tableController = self.tableController {
                view.setView(block(item, section), parentController: tableController)
            }
            return view
        }
        
        // Swipe actions support
        public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
            trailingActions[indexPath]
        }
        
        public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
            return leadingActions[indexPath]
        }
        
        //Context Menu support

        public func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
            return menuActions[indexPath]
        }
    }
}

private class InternalDataSource<SectionIdentifierType: Hashable, ItemIdentifierType: Hashable>: UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType> {
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
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

#if DEBUG

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

#endif

//
//  File.swift
//  
//
//  Created by Sergiy Loza on 05.05.2021.
//

import UIKit

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
    
    func addPullToRefresh(_ action: @escaping () -> Void) {
        if tableView.refreshControl != nil {
            return
        }
        
        if #available(iOS 14.0, *) {
            let refresh = UIRefreshControl(frame: .zero, primaryAction: UIAction(handler: { [weak self] (action) in
                self?.onRefresh()
            }))
            tableView.refreshControl = refresh
        } else {
            // Fallback on earlier versions
            let refresh = UIRefreshControl()
            refresh.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        }
        
        onPullToRefresh = action
    }
    
    private var onPullToRefresh: (() -> Void)?
    
    @objc func onRefresh() {
        onPullToRefresh?()
    }
}

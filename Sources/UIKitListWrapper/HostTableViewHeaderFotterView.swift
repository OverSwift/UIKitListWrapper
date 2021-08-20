//
//  HostTableViewHeaderFotterView.swift
//  CustomViews
//
//  Created by Sergiy Loza on 12.03.2021.
//

import Foundation
import SwiftUI

class HostTableViewHeaderFotterView<T: View>: UITableViewHeaderFooterView {
    
    private lazy var host: UIHostingController<HostCellView<T>> = {
        let hostController = UIHostingController(rootView: HostCellView<T>())
        hostController.view.translatesAutoresizingMaskIntoConstraints = false
        hostController.view.backgroundColor = .clear
        return hostController
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .clear
        backgroundView = { () -> UIView in
            let view = UIView()
            view.backgroundColor = .clear
            return view
        }()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        
    }
    
    func setView(_ view: T, parentController: UIViewController) {
        
        host.rootView = HostCellView {
            view
        }
        
        host.view.invalidateIntrinsicContentSize()
        
        let requiresControllerMove = host.parent != parentController
        if requiresControllerMove {
            parentController.addChild(host)
        }
        
        if !contentView.subviews.contains(host.view) {
            contentView.addSubview(host.view)
            
            NSLayoutConstraint.activate([
                contentView.topAnchor.constraint(equalTo: host.view.topAnchor),
                contentView.bottomAnchor.constraint(equalTo: host.view.bottomAnchor),
                contentView.leadingAnchor.constraint(equalTo: host.view.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: host.view.trailingAnchor)
            ])
        }
        
        if requiresControllerMove {
            host.didMove(toParent: parentController)
        }
    }
}

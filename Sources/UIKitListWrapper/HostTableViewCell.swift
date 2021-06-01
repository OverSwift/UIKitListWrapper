//
//  HostTableViewCell.swift
//  CustomViews
//
//  Created by Sergiy Loza on 12.03.2021.
//

import Foundation
import SwiftUI

class HostTableViewCell<T: View>: UITableViewCell {
    
    private(set) lazy var host: UIHostingController<HostCellView<T>> = {
        let hostController = UIHostingController(rootView: HostCellView<T>())
        hostController.view.translatesAutoresizingMaskIntoConstraints = false
        hostController.view.backgroundColor = .clear        
        return hostController
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        host.view.invalidateIntrinsicContentSize()
        host.view.setNeedsLayout()
        host.willMove(toParent: nil)
        host.view.removeFromSuperview()
        host.removeFromParent()
        host = {
            let hostController = UIHostingController(rootView: HostCellView<T>())
            hostController.view.translatesAutoresizingMaskIntoConstraints = false
            hostController.view.backgroundColor = .clear
            return hostController
        }()
        
        super.prepareForReuse()
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
            host.view.setNeedsLayout()
        }
        
        if requiresControllerMove {
            host.didMove(toParent: parentController)
        }
    }
}


//
//  HostCellView.swift
//  CustomViews
//
//  Created by Sergiy Loza on 12.03.2021.
//

import Foundation
import SwiftUI

struct HostCellView<Content>: View where Content: View {
    
    private var content: (() -> Content)?
    
    init() {
        self.content = nil
    }
    
    init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        if content != nil {
            content!()
                .frame(maxWidth: .infinity)
        } else {
            EmptyView()
        }
    }
}

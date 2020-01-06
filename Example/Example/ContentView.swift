//
//  ContentView.swift
//  Example
//
//  Created by Kazuki Yamamoto on 2019/12/28.
//  Copyright © 2019 kymmt. All rights reserved.
//

import SwiftUI
import KoratKit
import Logging

struct ContentView: View {
    @State private var count: Int = 0
    var body: some View {
        Button(action: {
            print("tapped: \(self.count)")
            self.count += 1
            logger.debug("tapped: \(self.count)")
            
        }) {
            Text("Counter")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

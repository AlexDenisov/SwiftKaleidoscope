//
//  main.swift
//  SwiftKaleidoscope
//
//  Created by AlexDenisov on 27/12/15.
//  Copyright © 2015 lowlevelbits. All rights reserved.
//

runloop:
while true {
    switch nextToken() {
    case .EOF: break runloop
    case let token: print("\(token)")
    }
}

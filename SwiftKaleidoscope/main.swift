//
//  main.swift
//  SwiftKaleidoscope
//
//  Created by AlexDenisov on 27/12/15.
//  Copyright © 2015 lowlevelbits. All rights reserved.
//

runloop:
while true {
    let char = getASCIICharacter()
    switch char {
    case ASCIICharacter.EOF: break runloop
    case _: print("\(char)")
    }
}
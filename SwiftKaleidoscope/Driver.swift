//
//  Driver.swift
//  SwiftKaleidoscope
//
//  Created by AlexDenisov on 03/01/16.
//  Copyright © 2016 lowlevelbits. All rights reserved.
//

func runloop() {
    codeGen()

    consumeToken()
runloop:
    while true {
        switch getCurrentToken() {
        case .Def: handleDefinition()
        case .Extern: handleExtern()
        case .Character(.Semicolon): consumeToken()
        case .EOF: break runloop
        case _: handleTopLevelExpression()
        }
    }
}

private func dump(dumpable: CustomStringConvertible) {
    print("\(dumpable.description)")
}

func handleDefinition() {
    do {
        let function = try parseFunctionDefintion()
        dump(function)
    }
    catch ParserError.Error(let reason) {
        print("parser error: \(reason)")
    }
    catch _ {
        print("How is it possible?")
    }
}

func handleExtern() {
    do {
        let externPrototype = try parseExternFunction()
        dump(externPrototype)
    }
    catch ParserError.Error(let reason) {
        print("parser error: \(reason)")
    }
    catch _ {
        print("How is it possible?")
    }
}

func handleTopLevelExpression() {
    do {
        let topLevel = try parseTopLevelExpression()
        dump(topLevel)
    }
    catch ParserError.Error(let reason) {
        print("parser error: \(reason)")
    }
    catch _ {
        print("How is it possible?")
    }
}

//
//  Driver.swift
//  SwiftKaleidoscope
//
//  Created by AlexDenisov on 03/01/16.
//  Copyright © 2016 lowlevelbits. All rights reserved.
//

import LLVM_C

let module = LLVMModuleCreateWithName("Kaleidoscope")
let builder = LLVMCreateBuilder()
let context = CodeGenContext(module: module, builder: builder, passManager: nil, namedValues: [String : LLVMValueRef]())

func runloop() {
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

private func dump(dumpable: LLVMValueRef) {
    LLVMDumpValue(dumpable)
}

func handleDefinition() {
    do {
        let function = try parseFunctionDefintion()
        let code = try function.codegen(context)
        dump(code)
    }
    catch ParserError.Error(let reason) {
        print("parser error: \(reason)")
    }
    catch CodeGenError.Error(let reason) {
        print("code gen error: \(reason)")
    }
    catch _ {
        print("How is it possible?")
    }
}

func handleExtern() {
    do {
        let externPrototype = try parseExternFunction()
        let code = try externPrototype.codegen(context)
        dump(code)
    }
    catch ParserError.Error(let reason) {
        print("parser error: \(reason)")
    }
    catch CodeGenError.Error(let reason) {
        print("code gen error: \(reason)")
    }
    catch _ {
        print("How is it possible?")
    }
}

func handleTopLevelExpression() {
    do {
        let topLevel = try parseTopLevelExpression()
        let code = try topLevel.codegen(context)
        dump(code)
    }
    catch ParserError.Error(let reason) {
        print("parser error: \(reason)")
    }
    catch CodeGenError.Error(let reason) {
        print("code gen error: \(reason)")
    }
    catch _ {
        print("How is it possible?")
    }
}

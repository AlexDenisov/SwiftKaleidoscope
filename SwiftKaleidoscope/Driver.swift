//
//  Driver.swift
//  SwiftKaleidoscope
//
//  Created by AlexDenisov on 03/01/16.
//  Copyright © 2016 lowlevelbits. All rights reserved.
//

import LLVM_C

func runloop() {
    LLVMLinkInMCJIT()
    LLVMInitializeNativeTarget()
    LLVMInitializeNativeAsmPrinter()

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
        let code = try function.codegen(currentCodeGenContext)
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
        let code = try externPrototype.codegen(currentCodeGenContext)
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
        let code = try topLevel.codegen(currentCodeGenContext)
        let result = runFunction(code, module: currentCodeGenContext.module)
        print("\(result)")
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

//
//  JIT.swift
//  SwiftKaleidoscope
//
//  Created by AlexDenisov on 04/01/16.
//  Copyright © 2016 lowlevelbits. All rights reserved.
//

import LLVM_C

func runFunction(function: LLVMValueRef, module: LLVMModuleRef) -> Double {
    let executionEngine = UnsafeMutablePointer<LLVMExecutionEngineRef>.alloc(strideof(LLVMExecutionEngineRef))
    let error = UnsafeMutablePointer<UnsafeMutablePointer<Int8>>.alloc(strideof(UnsafeMutablePointer<Int8>))

    defer {
        error.dealloc(strideof(UnsafeMutablePointer<Int8>))
        executionEngine.dealloc(strideof(LLVMExecutionEngineRef))
    }

    let res = LLVMCreateExecutionEngineForModule(executionEngine, module, error)
    if res != 0 {
        let msg = String.fromCString(error.memory)
        print("\(msg)")
        exit(1)
    }

    let value = LLVMRunFunction(executionEngine.memory, function, 0, nil)
    let result = LLVMGenericValueToFloat(LLVMDoubleType(), value)

    LLVMDeleteFunction(function)

    return result
}

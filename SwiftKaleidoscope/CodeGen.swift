//
//  CodeGen.swift
//  SwiftKaleidoscope
//
//  Created by AlexDenisov on 03/01/16.
//  Copyright © 2016 lowlevelbits. All rights reserved.
//

import LLVM_C

let module = LLVMModuleCreateWithName("Kaleidoscope")
func codeGen() {
    LLVMDumpModule(module)
}


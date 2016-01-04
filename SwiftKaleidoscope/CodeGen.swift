//
//  CodeGen.swift
//  SwiftKaleidoscope
//
//  Created by AlexDenisov on 03/01/16.
//  Copyright © 2016 lowlevelbits. All rights reserved.
//

import LLVM_C

struct CodeGenContext {
    let module: LLVMModuleRef
    let builder: LLVMBuilderRef
    let passManager: LLVMPassManagerRef
    var namedValues: [String : LLVMValueRef]
}

let module = LLVMModuleCreateWithName("Kaleidoscope")
let builder = LLVMCreateBuilder()
let passManager = passManagerForModule(module)

let currentCodeGenContext = CodeGenContext(module: module,
    builder: builder,
    passManager: passManager,
    namedValues: [String : LLVMValueRef]()
)

func passManagerForModule(module: LLVMModuleRef) -> LLVMPassManagerRef {
    let passManager = LLVMCreateFunctionPassManagerForModule(module)
    LLVMAddBasicAliasAnalysisPass(passManager)
    LLVMAddInstructionCombiningPass(passManager)
    LLVMAddReassociatePass(passManager)
    LLVMAddGVNPass(passManager)
    LLVMAddCFGSimplificationPass(passManager)

    LLVMInitializeFunctionPassManager(passManager)

    return passManager
}

enum CodeGenError : ErrorType {
    case Error(String)
}

protocol CodeGen {
    func codegen(context: CodeGenContext) throws -> LLVMValueRef
}

extension NumberExpr : CodeGen {
    func codegen(context: CodeGenContext) throws -> LLVMValueRef {
        return LLVMConstReal(LLVMDoubleType(), self.value)
    }
}

extension VariableExpr : CodeGen {
    func codegen(context: CodeGenContext) throws -> LLVMValueRef {
        if let value = context.namedValues[self.name] {
            return value
        }
        throw CodeGenError.Error("Can't find variable '\(self.name)'")
    }
}

extension BinaryExpr : CodeGen {
    func codegen(context: CodeGenContext) throws -> LLVMValueRef {
        do {
            let lhsValue = try (self.lhs as! CodeGen).codegen(context)
            let rhsValue = try (self.rhs as! CodeGen).codegen(context)

            switch self.binaryOperator {
            case ASCIICharacter.PlusSign: return LLVMBuildFAdd(context.builder, lhsValue, rhsValue, "addtemp")
            case ASCIICharacter.Minus: return LLVMBuildFSub(context.builder, lhsValue, rhsValue, "subtemp")
            case ASCIICharacter.Asterisk: return LLVMBuildFMul(context.builder, lhsValue, rhsValue, "multemp")
            case ASCIICharacter.LessThanSign:
                let cmp = LLVMBuildFCmp(context.builder, LLVMRealULT, lhsValue, rhsValue, "cmptemp")
                return LLVMBuildUIToFP(context.builder, cmp, LLVMDoubleType(), "booltmp")
                
            case _: throw CodeGenError.Error("Can't emit code for '\(self.description)'")
            }
        }
        catch CodeGenError.Error(let reason) {
            throw CodeGenError.Error(reason)
        }
    }
}

extension CallExpr : CodeGen {
    func codegen(context: CodeGenContext) throws -> LLVMValueRef {
        do {
            let function = LLVMGetNamedFunction(context.module, self.name)
            if function == nil {
                throw CodeGenError.Error("can't find function \(self.name)")
            }

            let paramsCount = LLVMCountParams(function)

            if Int(paramsCount) != self.arguments.count {
                throw CodeGenError.Error("invalid # of arguments passed to function \(self.name)")
            }

            var argumentValues = [LLVMValueRef]()
            for argument in self.arguments {
                let argumentValue = try (argument as! CodeGen).codegen(context)
                argumentValues.append(argumentValue)
            }

            /// FIXME: memory leak
            let argsPointer = UnsafeMutablePointer<LLVMValueRef>.alloc(arguments.count)
            argsPointer.initializeFrom(argumentValues)
            return LLVMBuildCall(context.builder, function, argsPointer, paramsCount, "calltmp")
        }
        catch CodeGenError.Error(let reason) {
            throw CodeGenError.Error(reason)
        }
    }
}

extension Prototype : CodeGen {
    func codegen(context: CodeGenContext) throws -> LLVMValueRef {
        let argumentsType: [LLVMTypeRef] = Array(count: self.arguments.count, repeatedValue: LLVMDoubleType())
        /// FIXME: memory leak
        let argumentsPointer = UnsafeMutablePointer<LLVMTypeRef>.alloc(arguments.count)
        argumentsPointer.initializeFrom(argumentsType)
        let functionType = LLVMFunctionType(LLVMDoubleType(), argumentsPointer, UInt32(arguments.count), 0)
        let function = LLVMAddFunction(context.module, self.name, functionType)

        var index = 0
        for argument in self.arguments {
            let param = LLVMGetParam(function, UInt32(index))
            index += 1
            LLVMSetValueName(param, argument)
        }

        return function
    }
}

extension Function : CodeGen {
    func codegen(var context: CodeGenContext) throws -> LLVMValueRef {
        do {
            var function = LLVMGetNamedFunction(context.module, self.prototype.name)
            if function == nil {
                function = try self.prototype.codegen(context)
            }

            if function == nil {
                throw CodeGenError.Error("can't codegen \(self.prototype.name)")
            }

            let entry = LLVMAppendBasicBlock(function, "entry")
            LLVMPositionBuilderAtEnd(context.builder, entry)
            context.namedValues.removeAll()

            let argsumentsCount = LLVMCountParams(function)
            for argumentIndex in 0..<argsumentsCount {
                let param = LLVMGetParam(function, argumentIndex)
                let name = String.fromCString(LLVMGetValueName(param))!
                context.namedValues[name] = param
            }

            let body = try (self.body as! CodeGen).codegen(context)
            if body == nil {
                LLVMDeleteFunction(function)
                throw CodeGenError.Error("Can't codegen '\(self.body.description)'")
            }

            LLVMBuildRet(context.builder, body)
            LLVMVerifyFunction(function, LLVMAbortProcessAction)
            LLVMRunFunctionPassManager(context.passManager, function)

            return function
        }
        catch CodeGenError.Error(let reason) {
            throw CodeGenError.Error(reason)
        }
    }
}

//
//  Parser.swift
//  SwiftKaleidoscope
//
//  Created by AlexDenisov on 02/01/16.
//  Copyright © 2016 lowlevelbits. All rights reserved.
//

protocol Expr : CustomStringConvertible {}

struct NumberExpr : Expr {
    let value: Double

    var description: String { get {
            return String(self.value)
        }
    }
}

struct VariableExpr : Expr {
    let name: String
    var description: String { get {
            return self.name
        }
    }
}

struct BinaryExpr : Expr {
    let binaryOperator: ASCIICharacter
    let lhs: Expr
    let rhs: Expr

    var description: String { get {
            return "("  + binaryOperator.description + " "
                        + lhs.description + " "
                        + rhs.description +
                    ")"
        }
    }

}

struct CallExpr : Expr {
    let name: String
    let arguments: [Expr]

    var description: String { get {
            var argumentsDescription = [String]()
            for argument in self.arguments {
                argumentsDescription.append(argument.description)
            }

            return self.name + "(" + argumentsDescription.joinWithSeparator(", ") + ")"
        }
    }
}

struct Prototype : CustomStringConvertible {
    let name: String
    let arguments: [String]

    var description: String { get {
            return self.name + "(" + arguments.joinWithSeparator(" ") + ")"
        }
    }
}

struct Function : CustomStringConvertible {
    let prototype: Prototype
    let body: Expr

    var description: String { get {
            if self.prototype.name == "" {
                return "__top_level_expression__\n" + self.body.description
            } else {
                return "def " + self.prototype.description + "\n" + self.body.description
            }
        }
    }
}

enum ParserError : ErrorType {
    case Error(String)
}

private var currentToken = Token.EOF
func consumeToken() {
    currentToken = nextToken()
}
func getCurrentToken() -> Token {
    return currentToken
}

private func isCurrentTokenCharacter(character: ASCIICharacter) -> Bool {
    switch currentToken {
    case .Character(let tokenCharacter): return tokenCharacter == character
    case _: return false
    }
}

let operatorPrecedence = [
    ASCIICharacter.LessThanSign : 10,
    ASCIICharacter.PlusSign : 20,
    ASCIICharacter.Minus : 20,
    ASCIICharacter.Asterisk : 40
]

func currentTokenPrecedence() -> Int {
    switch currentToken {
    case .Character(let character):
        let precedence = operatorPrecedence[character]
        switch precedence {
        case .Some(let precedence): return precedence
        case _: break
        }
    case _: break
    }

    return -1
}

// NumberExpr ::= number
func parseNumberExpression(number: Double) -> Expr {
    consumeToken()
    return NumberExpr(value: number)
}

// BinaryExpr ::= ('+' PrimaryExpr) *
func parseBinaryExpression(expressionPrecedence: Int, var lhs: Expr) throws -> Expr {
    while true {
        let currentPrecedence = currentTokenPrecedence()
        if currentPrecedence < expressionPrecedence {
            return lhs
        }

        let binaryOperator = currentToken
        consumeToken()

        do {
            var rhs = try parsePrimaryExpression()

            let nextPrecedence = currentTokenPrecedence()

            if currentPrecedence < nextPrecedence {
                rhs = try parseBinaryExpression(currentPrecedence + 1, lhs: rhs)
            }

            if case .Character(let character) = binaryOperator {
                lhs = BinaryExpr(binaryOperator: character, lhs: lhs, rhs: rhs)
            }
        }
        catch ParserError.Error(let reason) {
            throw ParserError.Error(reason)
        }
        catch _ {
            throw ParserError.Error("How is it possible?")
        }

    }
}

// Expression 
//      ::= PrimaryExpression BinaryExpression
func parseExpression() throws -> Expr {
    do {
        let lhs = try parsePrimaryExpression()
        return try parseBinaryExpression(0, lhs: lhs)
    }
    catch ParserError.Error(let reason) {
        throw ParserError.Error(reason)
    }
    catch _ {
        throw ParserError.Error("How is it possible?")
    }
}

// ParenExpr ::= '(' + Expression + ')'
func parseParenExpression() throws -> Expr {
    consumeToken() // eat '('

    do {
        let expression = try parseExpression()

        if !isCurrentTokenCharacter(.ParenthesesClosed) {
            throw ParserError.Error("expected ')'")
        }

        consumeToken() // eat ')'
        
        return expression
    }
    catch ParserError.Error(let reason) {
        throw ParserError.Error(reason)
    }
}

// IdentifierExpr
//   ::= identifier
//   ::= identifier '(' Expression* ')'
func parseIdentifierExpr(identifier: String) throws -> Expr {
    consumeToken()

    if !isCurrentTokenCharacter(.ParenthesesOpened) {
        return VariableExpr(name: identifier)
    }

    consumeToken() // eat '('

    var arguments = [Expr]()

    if !isCurrentTokenCharacter(.ParenthesesClosed) {
        do {
            while true {
                let argument = try parseExpression()
                arguments.append(argument)

                if isCurrentTokenCharacter(.ParenthesesClosed) {
                    break
                }

                if !isCurrentTokenCharacter(.Comma) {
                    throw ParserError.Error("expected ',' or ')'")
                }

                consumeToken()
            }
        }
        catch ParserError.Error(let reason) {
            throw ParserError.Error(reason)
        }
        catch _ {
            throw ParserError.Error("How is it possible?")
        }
    }

    consumeToken() // eat ')'

    return CallExpr(name: identifier, arguments: arguments)
}


// PrimaryExpr
//   ::= IdentifierExpr
//   ::= NumberExpr
//   ::= ParenExpr
func parsePrimaryExpression() throws -> Expr {
    switch currentToken {
    case .Number(let number): return parseNumberExpression(number)
    case .Identifier(let identifier): return try parseIdentifierExpr(identifier)
    case .Character(ASCIICharacter.ParenthesesOpened): return try parseParenExpression()
    case _:
        consumeToken()
        throw ParserError.Error("can't parse \(currentToken)")
    }
}

// Prototype
//      ::= IdentifierExpr '(' IdentifierExpr* ')'
func parsePrototype() throws -> Prototype {
    guard case .Identifier(let prototypeName) = currentToken else {
        throw ParserError.Error("expected prototype name")
    }

    consumeToken() // eat identifier

    if !isCurrentTokenCharacter(.ParenthesesOpened) {
        throw ParserError.Error("expected '(' in prototype")
    }

    consumeToken() // eat '('

    var argumentNames = [String]()

    while true {
        if case .Identifier(let identifier) = currentToken {
            argumentNames.append(identifier)
        } else {
            break
        }
        consumeToken()
    }

    if !isCurrentTokenCharacter(.ParenthesesClosed) {
        throw ParserError.Error("expected ')' in prototype")
    }

    consumeToken() // eat ')'

    return Prototype(name: prototypeName, arguments: argumentNames)
}


// FunctionDefinition
//      ::= def Prototype Expression
func parseFunctionDefintion() throws -> Function {
    do {
        consumeToken() // eat 'def'
        let prototype = try parsePrototype()
        let body = try parseExpression()
        return Function(prototype: prototype, body: body)
    }
    catch ParserError.Error(let reason) {
        throw ParserError.Error(reason)
    }
}

// FunctionDefinition
//      ::= extern Prototype
func parseExternFunction() throws -> Prototype {
    consumeToken() // eat 'extern'
    return try parsePrototype()
}

// TopLevelExpression
//      ::= Expression
func parseTopLevelExpression() throws -> Function {
    do {
        let topLevelExpr = try parseExpression()
        let prototype = Prototype(name: "", arguments: [])

        return Function(prototype: prototype, body: topLevelExpr)
    }
    catch ParserError.Error(let reason) {
        throw ParserError.Error(reason)
    }
}

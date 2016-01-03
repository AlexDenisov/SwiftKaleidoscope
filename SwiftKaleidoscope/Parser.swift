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

struct ErrorExpr : Expr {
    let reason: String

    var description: String { get {
            return "E:" + self.reason
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
            return "def " + self.prototype.description + "\n" + self.body.description
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
func parseBinaryExpression(expressionPrecedence: Int, var lhs: Expr) -> Expr {
    while true {
        let currentPrecedence = currentTokenPrecedence()
        if currentPrecedence < expressionPrecedence {
            return lhs
        }

        let binaryOperator = currentToken
        consumeToken()

        var rhs = parsePrimaryExpression()
        switch rhs {
        case is ErrorExpr: return rhs
        case _: break
        }

        let nextPrecedence = currentTokenPrecedence()
        if currentPrecedence < nextPrecedence {
            rhs = parseBinaryExpression(currentPrecedence + 1, lhs: rhs)
            switch rhs {
            case is ErrorExpr: return rhs
            case _: break
            }
        }

        switch binaryOperator {
        case .Character(let character):
            lhs = BinaryExpr(binaryOperator: character, lhs: lhs, rhs: rhs)
        case _: break
        }
    }
}

// Expression 
//      ::= PrimaryExpression BinaryExpression
func parseExpression() -> Expr {
    let lhs = parsePrimaryExpression()
    switch lhs {
    case is ErrorExpr: return lhs
    case _: return parseBinaryExpression(0, lhs: lhs)
    }
}

// ParenExpr ::= '(' + Expression + ')'
func parseParenExpression() -> Expr {
    consumeToken() // eat '('

    let expression = parseExpression()

    switch expression {
    case is ErrorExpr: return ErrorExpr(reason: "smth went wrong")
    case _: break
    }

    if !isCurrentTokenCharacter(.ParenthesesClosed) {
        return ErrorExpr(reason: "expected ')'")
    }

    consumeToken() // eat ')'

    return expression
}

// IdentifierExpr
//   ::= identifier
//   ::= identifier '(' Expression* ')'
func parseIdentifierExpr(identifier: String) -> Expr {
    consumeToken()

    if !isCurrentTokenCharacter(.ParenthesesOpened) {
        return VariableExpr(name: identifier)
    }

    consumeToken() // eat '('

    var arguments = [Expr]()

    if !isCurrentTokenCharacter(.ParenthesesClosed) {
        while true {
            let argument = parseExpression()
            switch argument {
            case is ErrorExpr: return argument
            case _: arguments.append(argument)
            }

            if isCurrentTokenCharacter(.ParenthesesClosed) {
                break
            }

            if !isCurrentTokenCharacter(.Comma) {
                return ErrorExpr(reason: "expected ',' or ')'")
            }

            consumeToken()
        }
    }

    consumeToken() // eat ')'

    return CallExpr(name: identifier, arguments: arguments)
}


// PrimaryExpr
//   ::= IdentifierExpr
//   ::= NumberExpr
//   ::= ParenExpr
func parsePrimaryExpression() -> Expr {
    switch currentToken {
    case .Number(let number): return parseNumberExpression(number)
    case .Identifier(let identifier): return parseIdentifierExpr(identifier)
    case .Character(ASCIICharacter.ParenthesesOpened): return parseParenExpression()
    case _:
        let err = ErrorExpr(reason: "can't parse \(currentToken)")
        consumeToken()
        return err
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
        let body = parseExpression()
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
func parseTopLevelExpression() -> Function {
    let topLevelExpr = parseExpression()
    let prototype = Prototype(name: "", arguments: [])

    return Function(prototype: prototype, body: topLevelExpr)
}

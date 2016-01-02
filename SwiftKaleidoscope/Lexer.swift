//
//  Lexer.swift
//  SwiftKaleidoscope
//
//  Created by AlexDenisov on 27/12/15.
//  Copyright © 2015 lowlevelbits. All rights reserved.
//

import Darwin

enum Token {
    case EOF
    case Def
    case Extern
    case Identifier(String)
    case Comment(String)
    case Number(Double)
    case Character(ASCIICharacter)
}

private typealias LexerPredicate = (ASCIICharacter -> Bool)

private let identifierPredicate: LexerPredicate = {
    $0 != .EOF && isAlphaNumericCharacter($0)
}

private let numberPredicate: LexerPredicate = {
    $0 != .EOF && isDigitCharacter($0 )
}

private let commentPredicate: LexerPredicate = {
    $0 != .EOF && $0 != .LineFeed && $0 != .CarriageReturn
}

private var currentCharacter = ASCIICharacter.Space

private func consumeUntil(predicate: LexerPredicate) -> String {
    var string = ""
    while predicate(currentCharacter) {
        string += String(UnicodeScalar(UInt32(currentCharacter.rawValue)))
        currentCharacter = getASCIICharacter()
    }

    return string
}

func nextToken() -> Token {
    while isSpaceCharacter(currentCharacter) {
        currentCharacter = getASCIICharacter()
    }

    // Attempt to create Identifier Token
    //
    // [A-Za-z][A-Za-z0-9]*
    if isAlphaCharacter(currentCharacter) {
        let identifier = consumeUntil(identifierPredicate)

        if identifier == "def" {
            return .Def
        }

        if identifier == "extern" {
            return .Extern
        }

        return .Identifier(identifier)
    }

    // Attempt to create Number Literal Token
    //
    // [0-9]+.?[0-9]*
    if isDigitCharacter(currentCharacter) {
        let integerPart = consumeUntil(numberPredicate)
        var decimalPoint = ""
        if currentCharacter == .FullStop {
            decimalPoint = "."
            currentCharacter = getASCIICharacter() // eat '.'
        }
        let fractionalPart = consumeUntil(numberPredicate)

        let numberString = integerPart + decimalPoint + fractionalPart
        if let number = Double(numberString) {
            return .Number(number)
        } else {
            print("lex error: can't parse number '\(numberString)'")
        }

    }

    // Consuming comments
    if currentCharacter == .NumberSign {
        let comment = consumeUntil(commentPredicate)
        return .Comment(comment)
    }

    // End of stream
    if currentCharacter == .EOF {
        return .EOF
    }

    let character = currentCharacter
    currentCharacter = getASCIICharacter()
    return .Character(character)
}

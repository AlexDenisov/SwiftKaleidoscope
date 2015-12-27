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
    case Number(Double)
    case Character(ASCIICharacter)
}

var currentToken = Token.EOF
func consumeToken() -> Void {

}

//
//  ASCIICharacters.swift
//  SwiftKaleidoscope
//
//  Created by AlexDenisov on 27/12/15.
//  Copyright © 2015 lowlevelbits. All rights reserved.
//

import Darwin

enum ASCIICharacter : Int32, CustomStringConvertible {
    case EOF = -1

    case NullTerminator           = 0x00
    case StartOfHeading           = 0x01
    case StartOfText              = 0x02
    case EndOfText                = 0x03
    case EndOfTransmission        = 0x04
    case Enquiry                  = 0x05
    case Acknowledgement          = 0x06
    case Bell                     = 0x07
    case Backspace                = 0x08
    case HorizontalTab            = 0x09 // \t
    case LineFeed                 = 0x0A // \n
    case VericalTab               = 0x0B // \v
    case FormFeed                 = 0x0C // \f
    case CarriageReturn           = 0x0D // \r
    case ShiftOut                 = 0x0E
    case ShiftIn                  = 0x0F
    case DataLinkEscape           = 0x10
    case DeviceControl1           = 0x11
    case DeviceControl2           = 0x12
    case DeviceControl3           = 0x13
    case DeviceControl4           = 0x14
    case NegativeAcknowledgement  = 0x15
    case SynchronousIdle          = 0x16
    case EndOfTransitionBlock     = 0x17
    case Cancel                   = 0x18
    case EndOfMedium              = 0x19
    case Substitute               = 0x1A
    case Escape                   = 0x1B
    case FileSeparator            = 0x1C
    case GroupSeparator           = 0x1D
    case RecordSeparator          = 0x1E
    case UnitSeparator            = 0x1F
    case Space                    = 0x20 // ' '
    case Exclamationmark          = 0x21 // !
    case Quotationmark            = 0x22 // "
    case NumberSign               = 0x23 // #
    case DollarSign               = 0x24 // $
    case PercentSign              = 0x25 // %
    case Ampersand                = 0x26 // &
    case Apostrophe               = 0x27 // '
    case ParenthesesOpened        = 0x28 // (
    case ParenthesesClosed        = 0x29 // )
    case Asterisk                 = 0x2A // *
    case PlusSign                 = 0x2B // +
    case Comma                    = 0x2C // ,
    case Minus                    = 0x2D // -
    case FullStop                 = 0x2E // .
    case Slash                    = 0x2F // /
    case Zero                     = 0x30 // 0
    case One                      = 0x31 // 1
    case Two                      = 0x32 // 2
    case Three                    = 0x33 // 3
    case Four                     = 0x34 // 4
    case Five                     = 0x35 // 5
    case Six                      = 0x36 // 6
    case Seven                    = 0x37 // 7
    case Eight                    = 0x38 // 8
    case Nine                     = 0x39 // 9
    case Colon                    = 0x3A // :
    case Semicolon                = 0x3B // ;
    case LessThanSign             = 0x3C // <
    case EqualsSign               = 0x3D // =
    case GreaterThanSign          = 0x3E // >
    case QuestionMark             = 0x3F // ?
    case AtSign                   = 0x40 // @
    case A                        = 0x41
    case B                        = 0x42
    case C                        = 0x43
    case D                        = 0x44
    case E                        = 0x45
    case F                        = 0x46
    case G                        = 0x47
    case H                        = 0x48
    case I                        = 0x49
    case J                        = 0x4A
    case K                        = 0x4B
    case L                        = 0x4C
    case M                        = 0x4D
    case N                        = 0x4E
    case O                        = 0x4F
    case P                        = 0x50
    case Q                        = 0x51
    case R                        = 0x52
    case S                        = 0x53
    case T                        = 0x54
    case U                        = 0x55
    case V                        = 0x56
    case W                        = 0x57
    case X                        = 0x58
    case Y                        = 0x59
    case Z                        = 0x5A
    case SquareBracketsOpened     = 0x5B // [
    case Backslash                = 0x5C // \
    case SquareBracketsClosed     = 0x5D // ]
    case Caret                    = 0x5E // ^
    case Underscore               = 0x5F // _
    case GraveAccent              = 0x60 // `
    case a                        = 0x61
    case b                        = 0x62
    case c                        = 0x63
    case d                        = 0x64
    case e                        = 0x65
    case f                        = 0x66
    case g                        = 0x67
    case h                        = 0x68
    case i                        = 0x69
    case j                        = 0x6A
    case k                        = 0x6B
    case l                        = 0x6C
    case m                        = 0x6D
    case n                        = 0x6E
    case o                        = 0x6F
    case p                        = 0x70
    case q                        = 0x71
    case r                        = 0x72
    case s                        = 0x73
    case t                        = 0x74
    case u                        = 0x75
    case v                        = 0x76
    case w                        = 0x77
    case x                        = 0x78
    case y                        = 0x79
    case z                        = 0x7A
    case BracketOpened            = 0x7B // {
    case VerticalBar              = 0x7C // |
    case BracketClosed            = 0x7D // }
    case Tilde                    = 0x7E // ~
    case Delete                   = 0x7F

    var description: String { get {
        if self == .EOF {
            return "EOF"
        }
        return String(UnicodeScalar(UInt32(self.rawValue)))
    }}
}

func getASCIICharacter() -> ASCIICharacter {
    let rawValue = getchar()
    let character = ASCIICharacter(rawValue: rawValue)
    switch character {
    case .Some(_): return character!
    case .None:
        print("lex error: skipping \(rawValue)")
        return getASCIICharacter()
    }
}

private func characterMatches(character: ASCIICharacter, predicate: (Int32) -> (Int32)) -> Bool {
    return predicate(character.rawValue) == Int32(1)
}

func isSpaceCharacter(character: ASCIICharacter) -> Bool {
    return characterMatches(character, predicate: isspace)
}

func isAlphaCharacter(character: ASCIICharacter) -> Bool {
    return characterMatches(character, predicate: isalpha)
}

func isAlphaNumericCharacter(character: ASCIICharacter) -> Bool {
    return characterMatches(character, predicate: isalnum)
}

func isDigitCharacter(character: ASCIICharacter) -> Bool {
    return characterMatches(character, predicate: isdigit)
}

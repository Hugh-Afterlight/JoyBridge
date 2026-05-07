import CoreGraphics
import Foundation

enum KeyboardKey: String, CaseIterable, Codable, Identifiable {
    case a
    case b
    case c
    case d
    case e
    case f
    case g
    case h
    case i
    case j
    case k
    case l
    case m
    case n
    case o
    case p
    case q
    case r
    case s
    case t
    case u
    case v
    case w
    case x
    case y
    case z

    case number0
    case number1
    case number2
    case number3
    case number4
    case number5
    case number6
    case number7
    case number8
    case number9

    case space
    case enter
    case escape
    case tab
    case upArrow
    case downArrow
    case leftArrow
    case rightArrow
    case delete
    case backspace
    case pageUp
    case pageDown
    case home
    case end

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .a:
            "A"
        case .b:
            "B"
        case .c:
            "C"
        case .d:
            "D"
        case .e:
            "E"
        case .f:
            "F"
        case .g:
            "G"
        case .h:
            "H"
        case .i:
            "I"
        case .j:
            "J"
        case .k:
            "K"
        case .l:
            "L"
        case .m:
            "M"
        case .n:
            "N"
        case .o:
            "O"
        case .p:
            "P"
        case .q:
            "Q"
        case .r:
            "R"
        case .s:
            "S"
        case .t:
            "T"
        case .u:
            "U"
        case .v:
            "V"
        case .w:
            "W"
        case .x:
            "X"
        case .y:
            "Y"
        case .z:
            "Z"
        case .number0:
            "0"
        case .number1:
            "1"
        case .number2:
            "2"
        case .number3:
            "3"
        case .number4:
            "4"
        case .number5:
            "5"
        case .number6:
            "6"
        case .number7:
            "7"
        case .number8:
            "8"
        case .number9:
            "9"
        case .space:
            "Space"
        case .enter:
            "Enter"
        case .escape:
            "Escape"
        case .tab:
            "Tab"
        case .upArrow:
            "Up Arrow"
        case .downArrow:
            "Down Arrow"
        case .leftArrow:
            "Left Arrow"
        case .rightArrow:
            "Right Arrow"
        case .delete:
            "Delete"
        case .backspace:
            "Backspace"
        case .pageUp:
            "Page Up"
        case .pageDown:
            "Page Down"
        case .home:
            "Home"
        case .end:
            "End"
        }
    }

    var keyCode: CGKeyCode {
        switch self {
        case .a:
            0
        case .s:
            1
        case .d:
            2
        case .f:
            3
        case .h:
            4
        case .g:
            5
        case .z:
            6
        case .x:
            7
        case .c:
            8
        case .v:
            9
        case .b:
            11
        case .q:
            12
        case .w:
            13
        case .e:
            14
        case .r:
            15
        case .y:
            16
        case .t:
            17
        case .number1:
            18
        case .number2:
            19
        case .number3:
            20
        case .number4:
            21
        case .number6:
            22
        case .number5:
            23
        case .number9:
            25
        case .number7:
            26
        case .number8:
            28
        case .number0:
            29
        case .o:
            31
        case .u:
            32
        case .i:
            34
        case .p:
            35
        case .enter:
            36
        case .l:
            37
        case .j:
            38
        case .k:
            40
        case .n:
            45
        case .m:
            46
        case .tab:
            48
        case .space:
            49
        case .backspace:
            51
        case .escape:
            53
        case .home:
            115
        case .pageUp:
            116
        case .delete:
            117
        case .end:
            119
        case .pageDown:
            121
        case .leftArrow:
            123
        case .rightArrow:
            124
        case .downArrow:
            125
        case .upArrow:
            126
        }
    }
}

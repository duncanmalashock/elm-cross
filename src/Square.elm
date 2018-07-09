module Square exposing (..)

import Coordinate exposing (Coordinate)
import Char


type Square
    = LetterSquare Coordinate Char EntryData
    | BlockSquare Coordinate


type alias EntryData =
    { startsEntries : StartsEntries
    , inAcrossEntry : Int
    , inDownEntry : Int
    }


type StartsEntries
    = StartsAcross
    | StartsDown
    | StartsAcrossAndDown
    | NoStart


blockChar : Char
blockChar =
    '*'


blankChar : Char
blankChar =
    '.'


letterChars : List Char
letterChars =
    String.toList ".ABCDEFGHIJKLMNOPQRSTUVWXYZ"


isLetterChar : Char -> Bool
isLetterChar char =
    List.member (Char.toUpper char) letterChars


isLetterSquare : Square -> Bool
isLetterSquare square =
    case square of
        LetterSquare _ _ _ ->
            True

        BlockSquare _ ->
            False


entryNumber : Square -> Maybe Int
entryNumber square =
    case square of
        LetterSquare _ _ entryData ->
            case entryData.startsEntries of
                StartsAcross ->
                    Just entryData.inAcrossEntry

                StartsDown ->
                    Just entryData.inDownEntry

                StartsAcrossAndDown ->
                    Just entryData.inAcrossEntry

                NoStart ->
                    Nothing

        BlockSquare _ ->
            Nothing


toString : Square -> String
toString s =
    case s of
        LetterSquare _ c _ ->
            String.fromChar c

        BlockSquare _ ->
            "*"

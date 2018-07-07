module Puzzle
    exposing
        ( Puzzle
        , Selection
        , EditMode(..)
        , fromString
        , selection
        , selectionCoordinate
        , switchSelectionDirection
        , setSelection
        , setSelectionDirection
        , clearSelection
        , moveSelectionLeft
        , moveSelectionRight
        , moveSelectionUp
        , moveSelectionDown
        , typeLetters
        , deleteLetter
        , setEditMode
        , updateEntry
        )

import Grid exposing (Grid)
import Entry exposing (Entry)
import Direction exposing (Direction(..))
import Coordinate exposing (Coordinate)
import KeyboardUtils
import Keyboard.Extra exposing (Key(..))
import Dict


-- TODO: puzzle should be the thing that's wrapped (in a result), not the grid


type alias Puzzle =
    { grid : Result String Grid
    , currentSelection : Maybe Selection
    , entryStartDict : Entry.EntryStartDict
    , entryMembershipDict : Entry.EntryMembershipDict
    , editMode : EditMode
    }


type alias Selection =
    ( Coordinate, Direction )


type EditMode
    = Solving
    | Editing


fromString : Int -> Int -> String -> EditMode -> Puzzle
fromString gridWidth gridHeight string editMode =
    let
        gridResult =
            Grid.fromString gridWidth gridHeight string

        gridDefault =
            Result.withDefault (Grid.blank 1 1) gridResult

        entryStartDict =
            Entry.entryStartDictFromGrid gridDefault

        entryMembershipDict =
            Entry.entryMembershipDictFromEntryStartDict gridDefault entryStartDict

        gridForDisplay =
            case editMode of
                Editing ->
                    gridResult

                Solving ->
                    Result.map Grid.clear gridResult
    in
        { grid = gridForDisplay
        , currentSelection = Nothing
        , entryStartDict = entryStartDict
        , entryMembershipDict = entryMembershipDict
        , editMode = editMode
        }


typeLetters : List Key -> Puzzle -> Puzzle
typeLetters keyList puzzle =
    List.foldl (\k -> typeLetter (KeyboardUtils.toLetterChar k))
        puzzle
        (KeyboardUtils.filterOnlyLetterKeys keyList)


typeLetter : Char -> Puzzle -> Puzzle
typeLetter char puzzle =
    case puzzle.currentSelection of
        Just ( coord, direction ) ->
            case direction of
                Across ->
                    { puzzle | grid = Result.map (Grid.updateLetterSquare coord char) puzzle.grid }
                        |> moveSelectionRight

                Down ->
                    { puzzle | grid = Result.map (Grid.updateLetterSquare coord char) puzzle.grid }
                        |> moveSelectionDown

        Nothing ->
            puzzle


deleteLetter : Puzzle -> Puzzle
deleteLetter puzzle =
    case puzzle.currentSelection of
        Just ( coord, direction ) ->
            case direction of
                Across ->
                    { puzzle | grid = Result.map (Grid.updateLetterSquare coord ' ') puzzle.grid }
                        |> moveSelectionLeft

                Down ->
                    { puzzle | grid = Result.map (Grid.updateLetterSquare coord ' ') puzzle.grid }
                        |> moveSelectionUp

        Nothing ->
            puzzle


selection : Puzzle -> Maybe Selection
selection puzzle =
    puzzle.currentSelection


selectionMapToCoordinate : (Coordinate -> Coordinate) -> Selection -> Selection
selectionMapToCoordinate function ( coord, direction ) =
    ( function coord, direction )


selectionCoordinate : Selection -> Coordinate
selectionCoordinate ( coord, direction ) =
    coord


switchSelectionDirection : Puzzle -> Puzzle
switchSelectionDirection puzzle =
    let
        updatedSelection =
            case puzzle.currentSelection of
                Just ( coord, direction ) ->
                    case direction of
                        Across ->
                            Just ( coord, Down )

                        Down ->
                            Just ( coord, Across )

                Nothing ->
                    Nothing
    in
        { puzzle | currentSelection = updatedSelection }


setSelectionDirection : Direction -> Puzzle -> Puzzle
setSelectionDirection direction puzzle =
    let
        updatedSelection =
            case puzzle.currentSelection of
                Just ( coord, _ ) ->
                    Just ( coord, direction )

                Nothing ->
                    Nothing
    in
        { puzzle | currentSelection = updatedSelection }


moveSelectionLeft : Puzzle -> Puzzle
moveSelectionLeft puzzle =
    moveSelection puzzle.currentSelection Coordinate.atLeft puzzle


moveSelectionRight : Puzzle -> Puzzle
moveSelectionRight puzzle =
    moveSelection puzzle.currentSelection Coordinate.atRight puzzle


moveSelectionUp : Puzzle -> Puzzle
moveSelectionUp puzzle =
    moveSelection puzzle.currentSelection Coordinate.above puzzle


moveSelectionDown : Puzzle -> Puzzle
moveSelectionDown puzzle =
    moveSelection puzzle.currentSelection Coordinate.below puzzle


moveSelection : Maybe Selection -> (Coordinate -> Coordinate) -> Puzzle -> Puzzle
moveSelection startingSelection newCoordFn puzzle =
    case puzzle.currentSelection of
        Just selection ->
            let
                ( newCoordToTry, direction ) =
                    selectionMapToCoordinate newCoordFn selection

                newCoordIsInBounds grid =
                    Grid.coordIsInBounds grid newCoordToTry

                newSquareIsPermitted grid =
                    (Grid.hasLetterSquareAt grid newCoordToTry)
                        || (puzzle.editMode == Editing)
            in
                case (Result.map newCoordIsInBounds puzzle.grid) of
                    Ok True ->
                        case (Result.map newSquareIsPermitted puzzle.grid) of
                            Ok True ->
                                setSelection newCoordToTry puzzle

                            Ok False ->
                                moveSelection
                                    startingSelection
                                    newCoordFn
                                    { puzzle
                                        | currentSelection =
                                            Maybe.map (\s -> selectionMapToCoordinate newCoordFn s)
                                                puzzle.currentSelection
                                    }

                            Err _ ->
                                puzzle

                    Ok False ->
                        { puzzle | currentSelection = startingSelection }

                    Err _ ->
                        puzzle

        Nothing ->
            puzzle


setSelection : Coordinate -> Puzzle -> Puzzle
setSelection (( x, y ) as coordinate) puzzle =
    case puzzle.grid of
        Ok grid ->
            let
                isInXBounds xVal =
                    xVal >= 0 && xVal < (Grid.width grid)

                isInYBounds yVal =
                    yVal >= 0 && yVal < (Grid.height grid)

                squareIsPermitted =
                    (Grid.hasLetterSquareAt grid coordinate)
                        || (puzzle.editMode == Editing)
            in
                if (isInXBounds x && isInYBounds y && squareIsPermitted) then
                    case puzzle.currentSelection of
                        Just selection ->
                            { puzzle
                                | currentSelection =
                                    Maybe.map
                                        (selectionMapToCoordinate (\_ -> coordinate))
                                        puzzle.currentSelection
                            }

                        Nothing ->
                            { puzzle | currentSelection = Just ( coordinate, Across ) }
                else
                    puzzle

        Err _ ->
            { puzzle | currentSelection = Nothing }


clearSelection : Puzzle -> Puzzle
clearSelection puzzle =
    { puzzle | currentSelection = Nothing }


setEditMode : EditMode -> Puzzle -> Puzzle
setEditMode editMode puzzle =
    { puzzle | editMode = editMode }


updateEntry : Puzzle -> Coordinate -> Entry -> Puzzle
updateEntry puzzle coordinate newClue =
    { puzzle | entryStartDict = Entry.updateEntry puzzle.entryStartDict coordinate newClue }
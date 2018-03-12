module Views exposing (..)

import Puzzle exposing (Selection)
import Grid exposing (Grid, Square(..))
import Entry exposing (EntryListings)
import Coordinate exposing (Coordinate)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)


gridView : Grid -> Maybe Selection -> EntryListings -> (Coordinate -> msg) -> Html msg
gridView grid currentSelection entryListings clickMsg =
    let
        drawRow : List ( Coordinate, Square ) -> Html msg
        drawRow coordsWithSquares =
            div []
                (List.map (\( coord, sq ) -> squareView grid currentSelection entryListings clickMsg coord sq)
                    coordsWithSquares
                )
    in
        (div
            [ style
                [ ( "display", "inline-block" )
                , ( "border-left", "1px solid gray" )
                , ( "border-top", "1px solid gray" )
                , ( "font-family", "Helvetica, Arial, sans-serif" )
                ]
            ]
        )
            (grid
                |> Grid.toRows
                |> List.map (drawRow)
            )


squareView : Grid -> Maybe Selection -> EntryListings -> (Coordinate -> msg) -> Coordinate -> Square -> Html msg
squareView grid currentSelection entryListings clickMsg (( x, y ) as coordinate) square =
    case square of
        LetterSquare letter ->
            let
                highlightStyle =
                    case currentSelection of
                        Just ( selectionCoordinate, direction ) ->
                            if coordinate == selectionCoordinate then
                                [ ( "background-color", "yellow" ) ]
                            else
                                []

                        Nothing ->
                            []

                entryStartView =
                    case Entry.entryNumberAt entryListings ( x, y ) of
                        Just i ->
                            [ div
                                [ style
                                    [ ( "position", "absolute" )
                                    , ( "top", "0px" )
                                    , ( "left", "2px" )
                                    , ( "font-size", "10px" )
                                    ]
                                ]
                                [ text <| toString i ]
                            ]

                        Nothing ->
                            []
            in
                div
                    [ class "square--open"
                    , onClick <| clickMsg ( x, y )
                    , style <|
                        [ ( "width", "32px" )
                        , ( "height", "32px" )
                        , ( "display", "inline-block" )
                        , ( "box-sizing", "border-box" )
                        , ( "vertical-align", "top" )
                        , ( "padding", "9px 0 0" )
                        , ( "font-size", "22px" )
                        , ( "text-align", "center" )
                        , ( "border-right", "1px solid gray" )
                        , ( "border-bottom", "1px solid gray" )
                        , ( "position", "relative" )
                        ]
                            ++ highlightStyle
                    ]
                    ([ text (String.fromChar letter)
                     ]
                        ++ entryStartView
                    )

        BlockSquare ->
            div
                [ class "square--filled"
                , onClick <| clickMsg ( x, y )
                , style
                    [ ( "width", "32px" )
                    , ( "height", "32px" )
                    , ( "display", "inline-block" )
                    , ( "background-color", "black" )
                    , ( "box-sizing", "border-box" )
                    , ( "vertical-align", "top" )
                    ]
                ]
                []


entriesView : EntryListings -> Html msg
entriesView entryListings =
    let
        acrossEntries =
            entryListings
                |> Entry.acrossList
                |> List.map entryView

        downEntries =
            entryListings
                |> Entry.downList
                |> List.map entryView
    in
        div
            [ style
                [ ( "display", "inline-block" )
                , ( "vertical-align", "top" )
                , ( "margin-left", "10px" )
                , ( "font-family", "Helvetica, Arial, sans-serif" )
                ]
            ]
            [ div
                [ style
                    [ ( "display", "inline-block" )
                    , ( "vertical-align", "top" )
                    , ( "margin-left", "10px" )
                    ]
                ]
                ((div [] [ text "Across" ])
                    :: acrossEntries
                )
            , div
                [ style
                    [ ( "display", "inline-block" )
                    , ( "vertical-align", "top" )
                    , ( "margin-left", "10px" )
                    ]
                ]
                ((div [] [ text "Down" ])
                    :: downEntries
                )
            ]


entryView : ( Int, String ) -> Html msg
entryView ( int, entry ) =
    div []
        [ text <| (toString int) ++ ": " ++ entry ]

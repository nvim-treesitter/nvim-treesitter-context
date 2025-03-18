module Test exposing (..)

import Html exposing (div, text)


main : Html.Html msg
-- {{TEST}}
main = -- {{CONTEXT}}
    let
        test =
            "Test content"
    in
    case test of -- {{CONTEXT}}
        "Hello" -> -- {{CONTEXT}}
            div []
                [ text "Hello, World!"
                , -- Generate some lines
                  -- Generate some lines
                  -- Generate some lines
                  -- Generate some lines
                  -- Generate some lines
                  -- Generate some lines
                  -- Generate some lines
                  -- Generate some lines
                  -- Generate some lines
                  -- Generate some lines
                  -- Generate some lines
                  -- Generate some lines
                  -- Generate some lines
                  -- Generate some lines
                  -- Generate some lines
                  -- Generate some lines
                  -- Generate some lines {{CURSOR}}
                  -- Generate some lines
                  -- Generate some lines
                  -- Generate some lines
                  -- Generate some lines
                  -- Generate some lines
                  -- Generate some lines
                  -- Generate some lines
                  div []
                    [ text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines" -- {{CURSOR}}
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    , text "Some more lines"
                    ]
                ] -- {{POPCONTEXT}}

        _ ->
            text "Default" -- {{CURSOR}}

module Main exposing (..)

import Html exposing (Html, text, div, h1, strong, input)
import Html.Attributes exposing (class)


---- MODEL ----


type alias Model =
    {}


init : ( Model, Cmd Msg )
init =
    ( {}, Cmd.none )



---- UPDATE ----


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ div [ class "bar" ]
            [ h1 [] [ text "Cozy ", strong [] [ text "Search" ] ]
            , input [ class "query" ] []
            , div [ class "menu" ] []
            ]
        , div [ class "sidebar" ] [ text "sidebar" ]
        , div [ class "results" ] [ text "results" ]
        ]



---- PROGRAM ----


main : Program Never Model Msg
main =
    Html.program
        { view = view
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }

module Main exposing (..)

import Debug exposing (log)
import Http
import Json.Decode
import Json.Decode.Pipeline
import Html exposing (Html, text, div, h1, strong, input, ul, li)
import Html.Attributes exposing (class, value)
import Html.Events exposing (onInput)
import OnEnter exposing (onEnter)


---- MODEL ----


type alias Hit =
    { id : String
    }


decodeHit : Json.Decode.Decoder Hit
decodeHit =
    Json.Decode.Pipeline.decode Hit
        |> Json.Decode.Pipeline.required "id" Json.Decode.string


type alias Results =
    { hits : List Hit
    , total : Int
    }


decodeResults : Json.Decode.Decoder Results
decodeResults =
    Json.Decode.Pipeline.decode Results
        |> Json.Decode.Pipeline.required "hits" (Json.Decode.list decodeHit)
        |> Json.Decode.Pipeline.required "total_hits" Json.Decode.int


type alias Model =
    { query : String
    , results : Maybe Results
    }


init : ( Model, Cmd Msg )
init =
    ( { query = "", results = Nothing }, Cmd.none )



---- UPDATE ----


type Msg
    = UpdateQuery String
    | Search
    | UpdateResults (Result Http.Error Results)


search : Model -> Cmd Msg
search model =
    let
        q =
            log "q" Http.encodeUri model.query

        uri =
            "http://cozy.tools:8080/search/io.cozy.contacts?q=" ++ q
    in
        Http.send UpdateResults <| Http.get uri decodeResults


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case
        log "msg" msg
    of
        UpdateQuery q ->
            ( { model | query = q }, Cmd.none )

        Search ->
            ( model, search model )

        UpdateResults (Ok res) ->
            ( { model | results = Just res }, Cmd.none )

        UpdateResults (Err _) ->
            ( { model | results = Nothing }, Cmd.none )



---- VIEW ----


query : Model -> Html Msg
query model =
    input
        [ class "query"
        , value model.query
        , onInput UpdateQuery
        , onEnter Search
        ]
        []


sidebar : Model -> Html Msg
sidebar model =
    div [ class "sidebar" ] [ text "" ]


hitToListItem : Hit -> Html Msg
hitToListItem hit =
    li [] [ text hit.id ]


results : Model -> Html Msg
results model =
    case
        model.results
    of
        Nothing ->
            div [ class "results" ]
                [ h1 [] [ text "Pas de résultats" ] ]

        Just results ->
            div [ class "results" ]
                [ h1 [] [ text ((toString results.total) ++ " résultats") ]
                , ul [] (List.map hitToListItem results.hits)
                ]


view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ div [ class "bar" ]
            [ h1 [] [ text "Cozy ", strong [] [ text "Search" ] ]
            , query model
            , div [ class "menu" ] []
            ]
        , sidebar model
        , results model
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

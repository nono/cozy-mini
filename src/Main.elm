module Main exposing (..)

import Debug exposing (log)
import Http
import Json.Decode
import Json.Decode.Pipeline exposing (decode, required, optional)
import Html exposing (Html, text, div, h1, h2, span, strong, input, ul, li)
import Html.Attributes exposing (class, value, style)
import Html.Events exposing (onInput)
import OnEnter exposing (onEnter)
import ColorHash exposing (getColor)


---- MODEL ----


type alias Email =
    { address : String
    }


decodeEmail : Json.Decode.Decoder Email
decodeEmail =
    decode Email
        |> required "address" Json.Decode.string


type alias Address =
    { street : String
    , city : String
    , postcode : String
    , country : String
    }


decodeAddress : Json.Decode.Decoder Address
decodeAddress =
    decode Address
        |> optional "street" Json.Decode.string ""
        |> optional "city" Json.Decode.string ""
        |> optional "post_code" Json.Decode.string ""
        |> optional "country" Json.Decode.string ""


type alias Phone =
    { number : String
    }


decodePhone : Json.Decode.Decoder Phone
decodePhone =
    decode Phone
        |> required "number" Json.Decode.string


type alias Cozy =
    { url : String
    }


decodeCozy : Json.Decode.Decoder Cozy
decodeCozy =
    decode Cozy
        |> required "url" Json.Decode.string


type alias Contact =
    { id : String
    , fullname : String
    , emails : List Email
    , addresses : List Address
    , phones : List Phone
    , cozys : List Cozy
    }


decodeContact : Json.Decode.Decoder Contact
decodeContact =
    decode Contact
        |> required "_id" Json.Decode.string
        |> required "fullname" Json.Decode.string
        |> optional "email" (Json.Decode.list decodeEmail) []
        |> optional "address" (Json.Decode.list decodeAddress) []
        |> optional "phone" (Json.Decode.list decodePhone) []
        |> optional "cozy" (Json.Decode.list decodeCozy) []


type alias Results =
    { hits : List Contact
    , total : Int
    }


decodeResults : Json.Decode.Decoder Results
decodeResults =
    decode Results
        |> required "hits" (Json.Decode.list decodeContact)
        |> required "total" Json.Decode.int


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


emailToDiv : Email -> Html Msg
emailToDiv email =
    div [ class "contact-email" ]
        [ span [ class "field-type" ] [ text "Courriel :" ]
        , text email.address
        ]


addressToDiv : Address -> Html Msg
addressToDiv address =
    div [ class "contact-address" ]
        [ span [ class "field-type" ] [ text "Addresse :" ]
        , text (address.street ++ " ")
        , text (address.postcode ++ " ")
        , text (address.city ++ " ")
        , text address.country
        ]


phoneToDiv : Phone -> Html Msg
phoneToDiv phone =
    div [ class "contact-phone" ]
        [ span [ class "field-type" ] [ text "Téléphone :" ]
        , text phone.number
        ]


cozyToDiv : Cozy -> Html Msg
cozyToDiv cozy =
    div [ class "contact-cozy" ]
        [ span [ class "field-type" ] [ text "Cozy :" ]
        , text cozy.url
        ]


contactToListItem : Contact -> Html Msg
contactToListItem contact =
    let
        initial =
            String.slice 0 1 contact.fullname

        bg =
            [ ( "background-color", getColor contact.fullname ) ]

        children =
            [ [ h2 [ class "contact-name" ]
                    [ div [ (class "contact-avatar"), (style bg) ] [ text initial ]
                    , span [] [ text contact.fullname ]
                    ]
              ]
            , List.map emailToDiv contact.emails
            , List.map addressToDiv contact.addresses
            , List.map phoneToDiv contact.phones
            , List.map cozyToDiv contact.cozys
            ]
    in
        li [ class "contact" ] (List.concat children)


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
                , ul [] (List.map contactToListItem results.hits)
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

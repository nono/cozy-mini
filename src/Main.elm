module Main exposing (..)

import Debug exposing (log)
import Http
import Json.Decode
import Json.Decode.Pipeline exposing (decode, required, optional)
import Html exposing (Html, text, div, h1, h2, span, strong, input, ul, li, a)
import Html.Attributes exposing (class, classList, value, style)
import Html.Events exposing (onInput, onClick)
import OnEnter exposing (onEnter)
import ColorHash exposing (getColor)
import Helpers exposing (diskSize)


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


type alias File =
    { id : String
    , class : String
    , name : String
    , size : String
    , updated : String
    }


decodeFile : Json.Decode.Decoder File
decodeFile =
    decode File
        |> required "_id" Json.Decode.string
        |> required "class" Json.Decode.string
        |> required "name" Json.Decode.string
        |> required "size" Json.Decode.string
        |> required "updated_at" Json.Decode.string


type Hits
    = Contacts (List Contact)
    | Files (List File)


type alias Results =
    { hits : Hits
    , total : Int
    }


decodeFilesResults : Json.Decode.Decoder Results
decodeFilesResults =
    decode Results
        |> required "hits" (Json.Decode.map (\a -> Files a) (Json.Decode.list decodeFile))
        |> required "total" Json.Decode.int


decodeContactsResults : Json.Decode.Decoder Results
decodeContactsResults =
    decode Results
        |> required "hits" (Json.Decode.map (\a -> Contacts a) (Json.Decode.list decodeContact))
        |> required "total" Json.Decode.int


type alias Model =
    { doctype : String
    , query : String
    , results : Maybe Results
    }


init : ( Model, Cmd Msg )
init =
    let
        model =
            { doctype = "contacts", query = "", results = Nothing }
    in
        ( model, search model )



---- UPDATE ----


type Msg
    = UpdateQuery String
    | Search
    | UpdateResults (Result Http.Error Results)
    | ChangeDoctype String


search : Model -> Cmd Msg
search model =
    let
        query =
            case
                model.query
            of
                "" ->
                    "*"

                _ ->
                    model.query

        q =
            log "q" Http.encodeUri query

        uri =
            "http://cozy.tools:8080/search/io.cozy." ++ model.doctype ++ "?q=" ++ q

        decoder =
            case
                model.doctype
            of
                "contacts" ->
                    decodeContactsResults

                "files" ->
                    decodeFilesResults

                _ ->
                    decodeFilesResults
    in
        Http.send UpdateResults <| Http.get uri decoder


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

        ChangeDoctype doctype ->
            let
                newModel =
                    { model | doctype = doctype }
            in
                ( newModel, search newModel )



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


doctypeSelector : String -> String -> Model -> Html Msg
doctypeSelector label doctype model =
    a
        [ classList
            [ ( "doctype-" ++ doctype, True )
            , ( "doctype-selected", doctype == model.doctype )
            ]
        , onClick (ChangeDoctype doctype)
        ]
        [ div [ class "icon" ] []
        , text label
        ]


sidebar : Model -> Html Msg
sidebar model =
    div [ class "sidebar" ]
        [ doctypeSelector "Contacts" "contacts" model
        , doctypeSelector "Fichiers" "files" model
        ]


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


fileToListItem : File -> Html Msg
fileToListItem file =
    li [ class "file" ]
        [ h2 [ class "file-name" ]
            [ div [ class ("file-type file-" ++ file.class) ] []
            , span [] [ text file.name ]
            ]
        , div [ class "file-size" ]
            [ span [ class "field-type" ] [ text "Taille :" ]
            , text (diskSize file.size)
            ]
        , div [ class "file-updated" ]
            [ span [ class "field-type" ] [ text "Mise à jour :" ]
            , text (String.slice 0 10 file.updated)
            ]
        ]


hitsToList : Hits -> Html Msg
hitsToList hits =
    case
        hits
    of
        Contacts contacts ->
            ul [] (List.map contactToListItem contacts)

        Files files ->
            ul [] (List.map fileToListItem files)


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
                , hitsToList results.hits
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

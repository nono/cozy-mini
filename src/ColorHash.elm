module ColorHash exposing (..)

import Char


scheme : List String
scheme =
    [ "304FFE", "2979FF", "00B0FF", "00DCE9", "00D5B8", "00C853", "E70505", "FF5700", "FF7900", "FFA300", "B3C51D", "64DD17", "FF2828", "F819AA", "AA00FF", "6200EA", "7190AB", "51658D" ]


nb : Int
nb =
    List.length scheme


hashCode : String -> Int
hashCode name =
    let
        hash =
            \c h ->
                (h * 31 + (Char.toCode c)) % nb
    in
        String.foldl hash 0 name


getColor : String -> String
getColor name =
    case
        List.head (List.drop (hashCode name) scheme)
    of
        Nothing ->
            ""

        Just s ->
            "#" ++ s

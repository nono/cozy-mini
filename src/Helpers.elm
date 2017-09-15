module Helpers exposing (..)


diskSize : String -> String
diskSize raw =
    case String.toInt raw of
        Err _ ->
            "inconnue"

        Ok size ->
            if size < 10 ^ 3 then
                (toString size) ++ " B"
            else if size < 10 ^ 6 then
                (toString (toFloat (size // 10 ^ 2) / 10)) ++ " KB"
            else if size < 10 ^ 9 then
                (toString (toFloat (size // 10 ^ 5) / 10)) ++ " MB"
            else
                (toString (toFloat (size // 10 ^ 9) / 10)) ++ " GB"

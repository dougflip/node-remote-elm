module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, type_, src, placeholder, value)
import Html.Events exposing (..)
import Http exposing (..)
import Json.Decode
import Json.Encode
import ElmEscapeHtml exposing (..)


main =
    programWithFlags
        { init = initWithFlags
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


initWithFlags : Config -> ( Model, Cmd a )
initWithFlags config =
    ( Model "" 50 50 config, Cmd.none )


type alias Config =
    { httpUrl : String }


type alias Model =
    { textToSend : String, volume : Int, restoreVolume : Int, config : Config }


type Msg
    = TextToSendChange String
    | SubmitTextToSend
    | ToggleMute
    | VolumeChange String
    | PostVolume (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TextToSendChange newText ->
            ( { model | textToSend = newText }, Cmd.none )

        SubmitTextToSend ->
            ( { model | textToSend = "" }, Cmd.none )

        ToggleMute ->
            let
                newVolume =
                    if model.volume > 0 then
                        0
                    else
                        model.restoreVolume

                newModel =
                    { model | volume = newVolume }
            in
                ( newModel, postVolume newModel )

        VolumeChange val ->
            let
                newVolume =
                    Result.withDefault model.volume (String.toInt val)

                newModel =
                    { model | volume = newVolume, restoreVolume = newVolume }
            in
                ( newModel, postVolume newModel )

        PostVolume _ ->
            ( model, Cmd.none )


postVolume : Model -> Cmd Msg
postVolume model =
    let
        url =
            (model.config.httpUrl ++ "/system/set-volume")

        volume =
            Json.Encode.object [ ( "level", Json.Encode.int model.volume ) ]

        jsonData =
            jsonBody volume

        req =
            Http.post url jsonData (Json.Decode.succeed "")
    in
        Http.send PostVolume req


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> Html Msg
view model =
    div [ class "app" ]
        [ div [ class "quick-commands" ]
            [ button [ class "close" ] [ text <| unescape "&times;" ]
            , button [ class "suspend" ] [ text "!" ]
            ]
        , div [ class "main-content" ]
            [ div [ class "volume-slider-wrapper" ]
                [ div [ class "speaker-icons", onClick ToggleMute ]
                    [ if model.volume <= 0 then
                        img [ class "mute", src "images/mute.svg" ] []
                      else
                        img [ class "mute", src "images/speaker.svg" ] []
                    ]
                , input [ class "volume-slider", type_ "range", onInput VolumeChange, value <| toString model.volume ] []
                ]
            , form [ class "send-text-form", onSubmit SubmitTextToSend ]
                [ input [ class "text-to-send", type_ "text", placeholder "Text to send", onInput TextToSendChange, value model.textToSend ] [] ]
            , div [ class "mousepad-container" ]
                [ div [ class "mousepad" ]
                    [ div [ class "touchpad" ] [] ]
                ]
            ]
        ]

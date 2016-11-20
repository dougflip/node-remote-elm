module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, type_, src, placeholder, value)
import Html.Events exposing (..)
import ElmEscapeHtml exposing (..)


main =
    program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : ( Model, Cmd Msg )
init =
    ( Model "" 50 50, Cmd.none )


type alias Model =
    { textToSend : String, volume : Int, restoreVolume : Int }


type Msg
    = TextToSendChange String
    | SubmitTextToSend
    | ToggleMute
    | VolumeChange String


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
            in
                ( { model | volume = newVolume }, Cmd.none )

        VolumeChange val ->
            let
                newVolume =
                    Result.withDefault model.volume (String.toInt val)
            in
                ( { model | volume = newVolume, restoreVolume = newVolume }, Cmd.none )


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

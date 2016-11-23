port module Main exposing (..)

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


type MouseClick
    = Left
    | Right


type Msg
    = TextToSendChange String
    | TextToSendPost
    | MuteToggle
    | VolumeChange String
    | LeftClickPost String
    | RightClickPost String
    | MouseMovePost ( Float, Float )
    | ScrollUpPost String
    | ScrollDownPost String
    | NoContentPostResult (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TextToSendChange newText ->
            ( { model | textToSend = newText }, Cmd.none )

        TextToSendPost ->
            ( { model | textToSend = "" }, postTextToSend model )

        MuteToggle ->
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

        LeftClickPost _ ->
            ( model, postMouseClick model Left )

        RightClickPost _ ->
            ( model, postMouseClick model Right )

        MouseMovePost points ->
            ( model, postMouseMove model points )

        ScrollUpPost _ ->
            ( model, postScrollUp model )

        ScrollDownPost _ ->
            ( model, postScrollDown model )

        NoContentPostResult _ ->
            ( model, Cmd.none )


postNoContent : String -> Http.Body -> Cmd Msg
postNoContent url body =
    Http.post url body (Json.Decode.succeed "")
        |> Http.send NoContentPostResult

postNoContentWithNoBody : String -> Cmd Msg
postNoContentWithNoBody url =
    postNoContent url Http.emptyBody


postTextToSend : Model -> Cmd Msg
postTextToSend model =
    let
        url =
            (model.config.httpUrl ++ "/keyboard/send-text")

        data =
            Json.Encode.object [ ( "text", Json.Encode.string (model.textToSend ++ "\n") ) ]
    in
        postNoContent url (jsonBody data)


postVolume : Model -> Cmd Msg
postVolume model =
    let
        url =
            (model.config.httpUrl ++ "/system/set-volume")

        data =
            Json.Encode.object [ ( "level", Json.Encode.int model.volume ) ]
    in
        postNoContent url (jsonBody data)


postMouseClick : Model -> MouseClick -> Cmd Msg
postMouseClick model click =
    let
        url =
            case click of
                Left ->
                    model.config.httpUrl ++ "/mouse/left-click"

                Right ->
                    model.config.httpUrl ++ "/mouse/right-click"
    in
        postNoContentWithNoBody url


postMouseMove : Model -> ( Float, Float ) -> Cmd Msg
postMouseMove model ( x, y ) =
    let
        url =
            (model.config.httpUrl ++ "/mouse/move-relative")

        data =
            Json.Encode.object [ ( "x", Json.Encode.float x ), ( "y", Json.Encode.float y ) ]
    in
        postNoContent url (jsonBody data)


postScrollUp : Model -> Cmd Msg
postScrollUp model =
    let
        url =
            (model.config.httpUrl ++ "/mouse/scroll-up")
    in
        postNoContentWithNoBody url


postScrollDown : Model -> Cmd Msg
postScrollDown model =
    let
        url =
            (model.config.httpUrl ++ "/mouse/scroll-down")
    in
        postNoContentWithNoBody url


port leftClick : (String -> msg) -> Sub msg


port rightClick : (String -> msg) -> Sub msg


port mouseMove : (( Float, Float ) -> msg) -> Sub msg


port scrollUp : (String -> msg) -> Sub msg


port scrollDown : (String -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ (leftClick LeftClickPost)
        , (rightClick RightClickPost)
        , (mouseMove MouseMovePost)
        , (scrollUp ScrollUpPost)
        , (scrollDown ScrollDownPost)
        ]


view : Model -> Html Msg
view model =
    div [ class "app" ]
        [ div [ class "quick-commands" ]
            [ button [ class "close" ] [ text <| unescape "&times;" ]
            , button [ class "suspend" ] [ text "!" ]
            ]
        , div [ class "main-content" ]
            [ div [ class "volume-slider-wrapper" ]
                [ div [ class "speaker-icons", onClick MuteToggle ]
                    [ if model.volume <= 0 then
                        img [ class "mute", src "images/mute.svg" ] []
                      else
                        img [ class "mute", src "images/speaker.svg" ] []
                    ]
                , input [ class "volume-slider", type_ "range", onInput VolumeChange, value <| toString model.volume ] []
                ]
            , form [ class "send-text-form", onSubmit TextToSendPost ]
                [ input [ class "text-to-send", type_ "text", placeholder "Text to send", onInput TextToSendChange, value model.textToSend ] [] ]
            , div [ class "mousepad-container" ]
                [ div [ class "mousepad" ]
                    [ div [ class "touchpad" ] [] ]
                ]
            ]
        ]

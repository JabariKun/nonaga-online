module Backend exposing (..)

-- import Nonaga as Game

import ClientState
import Dict
import Lamdera exposing (ClientId, SessionId, onConnect, onDisconnect, sendToFrontend)
import Nonaga exposing (Player(..))
import Rooms
import Set
import Types exposing (..)


type alias Model =
    BackendModel


app =
    Lamdera.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub BackendMsg
subscriptions model =
    Sub.batch [ onConnect ClientConnected, onDisconnect ClientDisconnected ]


initialModel : BackendModel
initialModel =
    { clients = Dict.empty
    , rooms = Rooms.empty
    }


init : ( Model, Cmd BackendMsg )
init =
    ( initialModel
    , Cmd.none
    )


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        ClientConnected sessionId clientId ->
            ( model, Cmd.none )

        ClientDisconnected sessionId clientId ->
            case Dict.get clientId model.clients of
                Nothing ->
                    ( model, Cmd.none )

                Just userId ->
                    let
                        newClients =
                            Dict.remove clientId model.clients

                        ( maybeRoom, newRooms ) =
                            Rooms.leave userId model.rooms
                    in
                    case maybeRoom of
                        Nothing ->
                            ( { model | clients = newClients }, Cmd.none )

                        Just room ->
                            ( { model | rooms = newRooms, clients = newClients }, updateRoomClients room model.clients )


updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend sessionId clientId msg model =
    case msg of
        ForwardGameMsg { userId, roomId, gameMsg } ->
            case Rooms.get roomId model.rooms of
                Nothing ->
                    ( model, Cmd.none )

                Just room ->
                    let
                        newRoom =
                            Rooms.handleGameMsg userId gameMsg room

                        newRooms =
                            Rooms.insert newRoom model.rooms

                        newModel =
                            { model | rooms = newRooms }
                    in
                    ( newModel
                    , updateRoomClients
                        newRoom
                        model.clients
                    )

        JoinOrCreateRoom maybeUserId roomId ->
            let
                roomToJoin =
                    Rooms.getWithDefault roomId model.rooms

                userId =
                    case maybeUserId of
                        Nothing ->
                            String.fromInt (7 + Dict.size model.clients)

                        Just id ->
                            id

                newRoomResult =
                    Rooms.join userId roomToJoin
            in
            case newRoomResult of
                Ok newRoom ->
                    let
                        newRooms =
                            Rooms.insert newRoom model.rooms

                        newClients =
                            Dict.insert userId clientId model.clients
                    in
                    ( { model | rooms = newRooms, clients = newClients }
                    , Cmd.batch
                        [ sendToFrontend clientId
                            (JoinedRoom
                                (ClientState.toClientState userId newRoom)
                            )
                        , updateRoomClients
                            newRoom
                            newClients
                        ]
                    )

                Err _ ->
                    ( model
                    , sendToFrontend clientId RoomFull
                    )


updateRoomClients : BackendRoom -> Clients -> Cmd BackendMsg
updateRoomClients room clients =
    let
        userList =
            Rooms.getUsers room
                |> Set.toList
    in
    userList
        |> List.filterMap
            (\userId ->
                Dict.get userId clients
                    |> Maybe.map (\clientId -> ( clientId, userId ))
            )
        |> List.map
            (\( clientId, userId ) ->
                sendToFrontend clientId
                    (UpdateRoom
                        (ClientState.toClientState userId room)
                    )
            )
        |> Cmd.batch


broadcastToRoom : BackendRoom -> Clients -> ToFrontend -> Cmd BackendMsg
broadcastToRoom room clients msg =
    Rooms.getUsers room
        |> Set.toList
        |> List.filterMap (\userId -> Dict.get userId clients)
        |> List.map (\clientId -> sendToFrontend clientId msg)
        |> Cmd.batch

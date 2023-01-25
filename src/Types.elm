module Types exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import ClientState
import Dict exposing (Dict)
import Element exposing (..)
import GraphicSVG.Widget as GraphicWidget
import Lamdera exposing (ClientId, SessionId)
import Nonaga as Game
import RoomId
import Rooms
import Url exposing (Url)


type alias FrontendModel =
    { key : Key
    , state : ClientState
    , gameWidgetState : GraphicWidget.Model
    }


type alias ClientState =
    ClientState.ClientState


type alias Rooms =
    Rooms.Rooms


type alias RoomId =
    RoomId.RoomId


type alias BackendRoom =
    Rooms.Room


type alias UserId =
    Rooms.UserId


type alias SessionData =
    { sessionId : SessionId, userId : UserId }


type alias Sessions =
    Dict SessionId SessionData


type alias Clients =
    Dict UserId ClientId


type alias BackendModel =
    { clients : Clients
    , rooms : Rooms
    }


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | NoOpFrontendMsg
    | GameWidgetMsg GraphicWidget.Msg
    | GameMsg Game.Msg
    | SubmitRoomId
    | SetRoomIdInputText String


type ToBackend
    = ForwardGameMsg { userId : UserId, roomId : RoomId, gameMsg : Game.Msg }
    | JoinOrCreateRoom (Maybe UserId) RoomId


type BackendMsg
    = ClientConnected SessionId ClientId
    | ClientDisconnected SessionId ClientId


type ToFrontend
    = JoinedRoom ClientState
    | LeftRoom
    | UpdateRoom ClientState
    | RoomFull

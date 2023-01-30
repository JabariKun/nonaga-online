module Components exposing (joinRoomForm, messagesColumn, playAgainButton, title)

import Element as El
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Events
import Material.Icons exposing (login)
import Material.Icons.Types exposing (Coloring(..))
import Types exposing (..)
import Widget as W
import Widget.Customize as Customize
import Widget.Icon exposing (Icon)
import Widget.Material as Material


palette =
    Material.defaultPalette


title text =
    El.el
        [ El.centerX
        , Font.size 24
        ]
        (El.text text)


joinRoomForm onSubmit roomId roomFull =
    let
        roomIdInput =
            { chips = []
            , text = roomId
            , placeholder = Just (Input.placeholder [] (El.text "Create or join a room"))
            , label = "roomId"
            , onChange = SetRoomIdInputText
            }
                |> W.textInput (Material.textInput palette)

        joinRoomButton =
            W.button
                (Material.containedButton palette
                    |> Customize.elementButton [ El.centerX ]
                )
                { text = "Enter room", icon = loginIcon, onPress = Just onSubmit }

        loginIcon =
            Material.Icons.login |> Widget.Icon.elmMaterialIcons Color

        errorMessage =
            El.el [ Font.size 12, El.centerX ]
                (El.text
                    (if roomFull then
                        "This room is full, please enter another."

                     else
                        " "
                    )
                )
    in
    El.el [ El.centerX ]
        (El.html
            (Html.form
                [ Html.Events.onSubmit onSubmit ]
                [ El.layout []
                    (El.column
                        [ El.spacing 12 ]
                        [ errorMessage
                        , roomIdInput
                        , joinRoomButton
                        ]
                    )
                ]
            )
        )


playAgainButton onClick =
    W.textButton
        (Material.containedButton palette
            |> Customize.elementButton [ El.centerX ]
        )
        { text = "Play again", onPress = Just onClick }


messagesColumn messages =
    El.column [ El.centerX, El.padding 8 ]
        (List.map (\m -> El.el [ El.centerX ] (El.text m)) messages)

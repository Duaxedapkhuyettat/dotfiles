/*
 *   Copyright 2016 David Edmundson <davidedmundson@kde.org>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2 or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */
import QtMultimedia

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasma5support 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents

import Qt5Compat.GraphicalEffects
import org.kde.kirigami 2.20 as Kirigami

import org.kde.breeze.components

import "components"
import "components/animation"

Item {
    id: root

    // If we're using software rendering, draw outlines instead of shadows
    // See https://bugs.kde.org/show_bug.cgi?id=398317
    readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software

    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
    Kirigami.Theme.inherit: false

    //width: 1600
    //height: 900

    property string notificationMessage
    property string clock_color: "#fff"

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    PlasmaCore.DataSource {
        id: keystateSource
        engine: "keystate"
        connectedSources: "Caps Lock"
    }

    //add me where ever the wallpaper tag or image is at
    Image {
        id: backgroundImage

        Video {
            id: videoPlayer
            anchors.fill: parent // Dynamically fill the parent Image
            source: "file:///usr/share/sddm/themes/breeze/xD.mp4" // Use file:// prefix
            loops: -1 // Use the same enum for looping
            muted: true
            // Start playback automatically when the component is ready
            Component.onCompleted: {
                videoPlayer.play()
            }
            height : 1080
            width : 1920
            // Optional: Add error handling for debugging
        }


        height: parent.height
        width: config.HaveFormBackground == "true" && config.FormPosition != "center" && config.PartialBlur != "true" ? parent.width - formBackground.width : parent.width
        anchors.left: leftleft ||
        leftcenter ?
        formBackground.right : undefined

            anchors.right: rightright ||
            rightcenter ?
            formBackground.left : undefined

                horizontalAlignment: config.BackgroundImageAlignment == "left" ?
                Image.AlignLeft :
                config.BackgroundImageAlignment == "right" ?
                Image.AlignRight :
                config.BackgroundImageAlignment == "center" ?
                Image.AlignHCenter : undefined

                source: config.background || config.Background
                fillMode: config.ScaleImageCropped == "true" ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                asynchronous: true
                cache: true
                clip: true
                mipmap: true
    }
    RejectPasswordAnimation {
        id: rejectPasswordAnimation
        target: mainStack
    }

    MouseArea {
        id: loginScreenRoot
        anchors.fill: parent

        property bool uiVisible: true
        property bool blockUI: mainStack.depth > 1 || userListComponent.mainPasswordBox.text.length > 0 || inputPanel.keyboardActive || config.type != "image"

        hoverEnabled: true
        drag.filterChildren: true
        onPressed: uiVisible = true;
        onPositionChanged: uiVisible = true;
        onUiVisibleChanged: {
            if (blockUI) {
                fadeoutTimer.running = false;
            } else if (uiVisible) {
                fadeoutTimer.restart();
            }
        }
        onBlockUIChanged: {
            if (blockUI) {
                fadeoutTimer.running = false;
                uiVisible = true;
            } else {
                fadeoutTimer.restart();
            }
        }

        Keys.onPressed: {
            uiVisible = true;
            event.accepted = false;
        }

        //takes one full minute for the ui to disappear
        Timer {
            id: fadeoutTimer
            running: true
            interval: 60000
            onTriggered: {
                if (!loginScreenRoot.blockUI) {
                    loginScreenRoot.uiVisible = false;
                }
            }
        }

        Clock {
            id: clock
            visible: true
            x: parent.width - width - 10
            y: parent.height - height - 10
        }


        StackView {
            id: mainStack
            anchors.left: parent.left
            height: root.height
            width: parent.width / 3

            focus: true //StackView is an implicit focus scope, so we need to give this focus so the item inside will have it

            Timer {
                //SDDM has a bug in 0.13 where even though we set the focus on the right item within the window, the window doesn't have focus
                //it is fixed in 6d5b36b28907b16280ff78995fef764bb0c573db which will be 0.14
                //we need to call "window->activate()" *After* it's been shown. We can't control that in QML so we use a shoddy timer
                //it's been this way for all Plasma 5.x without a huge problem
                running: true
                repeat: false
                interval: 200
                onTriggered: mainStack.forceActiveFocus()
            }

            initialItem: Login {
                id: userListComponent
                userListModel: userModel
                loginScreenUiVisible: loginScreenRoot.uiVisible
                userListCurrentIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
                lastUserName: userModel.lastUser

                showUserList: {
                    if ( !userListModel.hasOwnProperty("count")
                    || !userListModel.hasOwnProperty("disableAvatarsThreshold"))
                        return false

                    if ( userListModel.count == 0 ) return false

                    return userListModel.count <= userListModel.disableAvatarsThreshold && (userList.y + mainStack.y) > 0
                }

                notificationMessage: {
                    const parts = [];
                    if (keystateSource.data["Caps Lock"]["Locked"]) {
                        parts.push(i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Caps Lock is on"));
                    }
                    if (root.notificationMessage) {
                        parts.push(root.notificationMessage);
                    }
                    return parts.join(" • ");
                }

                actionItems: [
                    ActionButton {
                        iconSource: Qt.resolvedUrl("assets/suspend.svgz")
                        text: i18ndc("plasma_lookandfeel_org.kde.lookandfeel","Suspend to RAM","Sleep")                        
                        onClicked: sddm.suspend()
                        enabled: sddm.canSuspend
                        visible: !inputPanel.keyboardActive
                    },
                    ActionButton {
                        iconSource: Qt.resolvedUrl("assets/restart.svgz")
                        text: i18nd("plasma_lookandfeel_org.kde.lookandfeel","Restart")
                        onClicked: sddm.reboot()
                        enabled: sddm.canReboot
                        visible: !inputPanel.keyboardActive
                    },
                    ActionButton {
                        iconSource: Qt.resolvedUrl("assets/shutdown.svgz")
                        text: i18nd("plasma_lookandfeel_org.kde.lookandfeel","Shut Down")
                        onClicked: sddm.powerOff()
                        enabled: sddm.canPowerOff
                        visible: !inputPanel.keyboardActive
                    },
                    ActionButton {
                        iconSource: Qt.resolvedUrl("assets/change_user.svgz")
                        text: i18nd("plasma_lookandfeel_org.kde.lookandfeel","Different User")
                        onClicked: mainStack.push(userPromptComponent)
                        enabled: true
                        visible: !userListComponent.showUsernamePrompt && !inputPanel.keyboardActive
                    }]

                onLoginRequest: {
                    root.notificationMessage = ""
                    sddm.login(username, password, sessionIndex)
                }
            }

            pushEnter: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 0
                    to:1
                    duration: 200
                }
            }
            pushExit: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 1
                    to:0
                    duration: 200
                }
            }
            popEnter: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 0
                    to:1
                    duration: 200
                }
            }
            popExit: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 1
                    to:0
                    duration: 200
                }
            }

            Behavior on opacity {
                OpacityAnimator {
                    duration: units.longDuration
                }
            }
        }

        VirtualKeyboardLoader {
            id: inputPanel

            z: 1

            screenRoot: root
            mainStack: mainStack
            mainBlock: userListComponent
            passwordField: userListComponent.mainPasswordBox
        }


        Component {
            id: userPromptComponent
            Login {
                showUsernamePrompt: true
                notificationMessage: root.notificationMessage
                loginScreenUiVisible: loginScreenRoot.uiVisible

                // using a model rather than a QObject list to avoid QTBUG-75900
                userListModel: ListModel {
                    ListElement {
                        name: ""
                        iconSource: ""
                    }
                    Component.onCompleted: {
                        // as we can't bind inside ListElement
                        setProperty(0, "name", i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Type in Username and Password"));
                        setProperty(0, "icon", Qt.resolvedUrl("faces/.face.icon"))
                    }
                }

                onLoginRequest: {
                    root.notificationMessage = ""
                    sddm.login(username, password, sessionIndex)
                }

                actionItems: [
                    ActionButton {
                        iconSource: Qt.resolvedUrl("assets/suspend.svgz")
                        text: i18ndc("plasma_lookandfeel_org.kde.lookandfeel","Suspend to RAM","Sleep")                        
                        onClicked: sddm.suspend()
                        enabled: sddm.canSuspend
                        visible: !inputPanel.keyboardActive
                    },
                    ActionButton {
                        iconSource: Qt.resolvedUrl("assets/restart.svgz")
                        text: i18nd("plasma_lookandfeel_org.kde.lookandfeel","Restart")
                        onClicked: sddm.reboot()
                        enabled: sddm.canReboot
                        visible: !inputPanel.keyboardActive
                    },
                    ActionButton {
                        iconSource: Qt.resolvedUrl("assets/shutdown.svgz")
                        text: i18nd("plasma_lookandfeel_org.kde.lookandfeel","Shut Down")
                        onClicked: sddm.powerOff()
                        enabled: sddm.canPowerOff
                        visible: !inputPanel.keyboardActive
                    },
                    ActionButton {
                        iconSource: "go-previous"
                        text: i18nd("plasma_lookandfeel_org.kde.lookandfeel","List Users")
                        onClicked: mainStack.pop()
                        visible: !inputPanel.keyboardActive
                    }
                ]
            }
        }

        // Rectangle {
        //     id: formBg
        //     anchors.fill: mainStack
        //     anchors.centerIn: mainStack
        //     color: "#161925"
        //     opacity: 0.4
        //     z:-1
        // }

        ShaderEffectSource {
            id: blurArea
            sourceItem: Image
            
            anchors.fill: parent
            
            sourceRect: Qt.rect(x,y,width,height)
            visible: true
            z:-2
        }

        GaussianBlur {
            id: blur
            height: blurArea.height
            width: blurArea.width
            source: blurArea
            radius: 75
            samples: 50 * 2 + 1
            cached: true
         //   anchors.centerIn: formBg
            visible: true
            z:-2
        }
    }

    Connections {
        target: sddm
        onLoginFailed: {
            notificationMessage = i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Login Failed >~<")
            rejectPasswordAnimation.start()
        }
        onLoginSucceeded: {
            //note SDDM will kill the greeter at some random point after this
            //there is no certainty any transition will finish, it depends on the time it
            //takes to complete the init
            mainStack.opacity = 0
            footer.opacity = 0
        }
    }

    onNotificationMessageChanged: {
        if (notificationMessage) {
            notificationResetTimer.start();
        }
    }

    Timer {
        id: notificationResetTimer
        interval: 3000
        onTriggered: notificationMessage = ""
    }
}

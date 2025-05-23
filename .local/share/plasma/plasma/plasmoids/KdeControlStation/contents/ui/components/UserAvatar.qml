import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents2
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components 1.0 as KirigamiComponents
import org.kde.kcmutils as KCM
import org.kde.coreaddons 1.0 as KCoreAddons
import "../lib" as Lib

Lib.Card {
    id: useraAvatar

    Layout.fillWidth: true
    Layout.preferredHeight: root.sectionHeight/3.3

    visible: root.showAvatar

    smallTopMargins: true
    smallBottomMargins: true

    property bool singleLineWidget: false

    KCoreAddons.KUser {
      id: kuser
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: root.mediumSpacing
        
        clip: true
        
        Rectangle {
            width: (35 * 1)  
            height: width
            color: "transparent"
            radius: width / 2
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHLeft
            KirigamiComponents.AvatarButton {
                source: kuser.faceIconUrl
                anchors {
                    fill: parent
                }
            }
        }

        ColumnLayout {
            anchors.margins: 1
            spacing: 1
            PlasmaComponents.Label {
                id: userName
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.margins: root.smallSpacing
                text: kuser.fullName // i18n("%1@%2", kuser.loginName, kuser.host)
                font.pixelSize:  root.mediumFontSize + 2
                font.weight: Font.Bold
                horizontalAlignment:  Qt.AlignLeft
                verticalAlignment: Qt.AlignVCenter
                wrapMode: Text.WordWrap
            }

            PlasmaComponents.Label {
                id: userHost
                visible: !singleLineWidget
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.margins: root.smallSpacing
                text: i18n("%1@%2", kuser.loginName, kuser.host)
                font.pixelSize:  root.smallFontSize + 2
               // font.weight: Font.Bold
                horizontalAlignment:  Qt.AlignLeft
                verticalAlignment: Qt.AlignVCenter
                wrapMode: Text.WordWrap
            }

        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: false
        onClicked: {
            KCM.KCMLauncher.openSystemSettings("kcm_users")
            root.toggle()
        }
    }
}




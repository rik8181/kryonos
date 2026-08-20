import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
// Qt6 / Plasma 6 (a jelenlegi Bazzite alap ezt használja) — ha a
// tesztkörnyezeted még Qt5/Plasma 5 SDDM-et futtat, cseréld erre:
//   import QtGraphicalEffects 1.15
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height

    // ============================================================
    // Színek / konfiguráció (theme.conf-ból, de itt hardkódolt
    // fallback is van, ha a config betöltés valamiért nem sikerülne)
    // ============================================================
    property color bgTop: config.backgroundTopColor || "#0d0f17"
    property color bgBottom: config.backgroundBottomColor || "#05060a"
    property color accentFrom: config.accentFrom || "#a855f7"
    property color accentTo: config.accentTo || "#3b82f6"

    // ============================================================
    // Háttér: sötét gradiens + két lágy, márkaszínű "glow" folt,
    // hogy ne legyen teljesen lapos a háttér (ugyanaz a hangulat,
    // mint a boot splash-en és a logóban)
    // ============================================================
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: bgTop }
            GradientStop { position: 1.0; color: bgBottom }
        }
    }

    Rectangle {
        id: glowPurple
        width: parent.width * 0.5
        height: width
        radius: width / 2
        color: accentFrom
        opacity: 0.16
        x: -width * 0.25
        y: -height * 0.3
        layer.enabled: true
        layer.effect: FastBlur { radius: 120 }
    }

    Rectangle {
        id: glowBlue
        width: parent.width * 0.4
        height: width
        radius: width / 2
        color: accentTo
        opacity: 0.14
        x: parent.width - width * 0.75
        y: parent.height - height * 0.6
        layer.enabled: true
        layer.effect: FastBlur { radius: 120 }
    }

    // ============================================================
    // Óra + dátum, felül középen (macOS lock screen stílus)
    // ============================================================
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.09
        spacing: 4
        visible: config.showClock !== "false"

        Text {
            id: clockText
            anchors.horizontalCenter: parent.horizontalCenter
            color: "white"
            font.pixelSize: 64
            font.weight: Font.Light
            text: Qt.formatTime(new Date(), "hh:mm")
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#c9cdd8"
            font.pixelSize: 16
            text: Qt.formatDate(new Date(), "dddd, MMMM d")
        }
    }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: clockText.text = Qt.formatTime(new Date(), "hh:mm")
    }

    // ============================================================
    // A "glass" bejelentkező kártya — a lényeg: háttér-elmosás
    // (ShaderEffectSource + FastBlur) + félig áttetsző, lekerekített
    // panel, pont mint a KWin ablakdekorációnk "glass effect"-je.
    // ============================================================
    Item {
        id: card
        width: 380
        height: cardColumn.implicitHeight + 64
        anchors.centerIn: parent

        ShaderEffectSource {
            id: bgSource
            sourceItem: root
            sourceRect: Qt.rect(card.x, card.y, card.width, card.height)
            visible: false
        }
        FastBlur {
            anchors.fill: parent
            source: bgSource
            radius: 64
        }
        Rectangle {
            anchors.fill: parent
            radius: 20
            color: "#1c1d21"
            opacity: 0.45
            border.color: "#ffffff"
            border.width: 1
            antialiasing: true
        }
        // Finom felső highlight-csík, ahogy a KWin decoration.svg-ben is
        Rectangle {
            width: parent.width
            height: parent.height * 0.35
            radius: 20
            anchors.top: parent.top
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#33ffffff" }
                GradientStop { position: 1.0; color: "#00ffffff" }
            }
        }

        Column {
            id: cardColumn
            width: parent.width - 64
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 32
            spacing: 18

            // --- Logó + wordmark ---
            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                source: "assets/logo.png"
                fillMode: Image.PreserveAspectFit
                height: 72
            }
            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                source: "assets/wordmark.png"
                fillMode: Image.PreserveAspectFit
                height: 22
            }

            Item { width: 1; height: 6 }

            // --- Felhasználó-választó ---
            ComboBox {
                id: userCombo
                width: parent.width
                model: userModel
                textRole: "name"
                currentIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
                background: Rectangle {
                    radius: 10
                    color: "#26ffffff"
                    border.color: "#40ffffff"
                }
                contentItem: Text {
                    text: userCombo.displayText
                    color: "white"
                    leftPadding: 12
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // --- Jelszó mező ---
            TextField {
                id: passwordField
                width: parent.width
                placeholderText: qsTr("Jelszó")
                echoMode: TextInput.Password
                color: "white"
                placeholderTextColor: "#9aa0ad"
                background: Rectangle {
                    radius: 10
                    color: "#26ffffff"
                    border.color: passwordField.activeFocus ? accentFrom : "#40ffffff"
                    border.width: passwordField.activeFocus ? 1.5 : 1
                }
                leftPadding: 12
                Keys.onReturnPressed: loginButton.doLogin()
                Keys.onEnterPressed: loginButton.doLogin()
                focus: true
            }

            // --- Bejelentkezés gomb, akcent-gradienssel ---
            Rectangle {
                id: loginButton
                width: parent.width
                height: 42
                radius: 10
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: accentFrom }
                    GradientStop { position: 1.0; color: accentTo }
                }

                function doLogin() {
                    // Egyszerűsített, széles körben működő minta: a
                    // ComboBox megjelenített szövege maga a felhasználónév.
                    // Ha a rendszereden a display name eltér a login
                    // névtől, cseréld userModel egyedi role-lekérdezésre.
                    sddm.login(userCombo.currentText, passwordField.text, sessionCombo.currentIndex)
                }

                Text {
                    anchors.centerIn: parent
                    text: qsTr("Bejelentkezés")
                    color: "white"
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: loginButton.doLogin()
                }
            }

            // --- Session-választó (Plasma / Plasma (Wayland) / stb.) ---
            ComboBox {
                id: sessionCombo
                width: parent.width
                model: sessionModel
                textRole: "name"
                currentIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
                background: Rectangle {
                    radius: 10
                    color: "transparent"
                }
                contentItem: Text {
                    text: sessionCombo.displayText
                    color: "#9aa0ad"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                }
                indicator: Item {}
            }
        }
    }

    // ============================================================
    // Power gombok — jobb alsó sarok
    // ============================================================
    Row {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 24
        spacing: 16

        Repeater {
            model: [
                { icon: "⏾", visible: sddm.canSuspend, action: function() { sddm.suspend() } },
                { icon: "⟲", visible: sddm.canReboot,  action: function() { sddm.reboot() } },
                { icon: "⏻", visible: sddm.canPowerOff, action: function() { sddm.powerOff() } }
            ]
            delegate: Rectangle {
                visible: modelData.visible
                width: 40; height: 40; radius: 20
                color: mouseArea.containsMouse ? "#33ffffff" : "#1affffff"
                Text {
                    anchors.centerIn: parent
                    text: modelData.icon
                    color: "white"
                    font.pixelSize: 18
                }
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.action()
                }
            }
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            passwordField.text = ""
            passwordField.placeholderText = qsTr("Hibás jelszó — próbáld újra")
        }
    }

    Component.onCompleted: passwordField.forceActiveFocus()
}

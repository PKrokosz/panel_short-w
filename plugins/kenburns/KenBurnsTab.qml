import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    width: 480
    height: 320

    ColumnLayout {
        anchors.fill: parent
        spacing: 8
        padding: 8

        TextField {
            id: argField
            placeholderText: "--help"
            Layout.fillWidth: true
        }

        RowLayout {
            Button {
                text: "Run"
                onClicked: KenBurns.run(argField.text)
            }
            Button {
                text: "Stop"
                onClicked: KenBurns.stop()
            }
            Button {
                text: "Save preset"
                onClicked: KenBurns.savePreset("custom_preset.json", argField.text)
            }
        }

        TextArea {
            id: logArea
            readOnly: true
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    Connections {
        target: KenBurns
        function onOutput(msg) {
            logArea.append(msg)
            logArea.cursorPosition = logArea.length
        }
        function onFinished(code) {
            toast.text = code === 0 ? "Process finished" : "Process failed";
            toast.color = code === 0 ? "#444444" : "#E74C3C";
            toast.visible = true;
            logArea.append("[EXIT] " + code)
            logArea.cursorPosition = logArea.length
        }
    }

    Rectangle {
        id: toast
        property string text: ""
        width: parent.width
        height: 30
        anchors.bottom: parent.bottom
        color: "#444444"
        visible: opacity > 0
        opacity: 0
        Text { anchors.centerIn: parent; color: "white"; text: parent.text }
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Timer { id: toastTimer; interval: 2000; onTriggered: toast.opacity = 0 }
        function show(msg, ok) {
            text = msg
            color = ok ? "#444444" : "#E74C3C"
            opacity = 1
            toastTimer.restart()
        }
    }
}

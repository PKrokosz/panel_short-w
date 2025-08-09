import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects 1.15
import QtQuick.Window 2.15

Window {
    id: root
    width: 480
    height: 320
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool

    Rectangle {
        id: glass
        anchors.fill: parent
        color: "#202020"
        opacity: 0.8
    }

    MultiEffect {
        anchors.fill: glass
        source: glass
        blurEnabled: true
        blur: 0.4
    }

    property var statuses: Bridge.getStatuses()
    property bool ctState: Bridge.getClickThrough()
    property var logLines: []

    function stateColor(st) {
        if (st === "ok") return "#3ECF8E";
        if (st === "warn") return "#F5A623";
        if (st === "fail") return "#E74C3C";
        return "#7A7A7A";
    }

    Column {
        id: mainCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: logPanel.visible ? logPanel.top : parent.bottom
        anchors.margins: 8
        spacing: 8

        Rectangle {
            id: header
            width: parent.width
            height: 40
            color: "#303030"
            opacity: 0.9
            Row {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                ComboBox {
                    id: modeBox
                    model: Bridge.getModes()
                    Component.onCompleted: {
                        var idx = Bridge.getModes().indexOf(Bridge.getMode());
                        currentIndex = idx >= 0 ? idx : 0;
                    }
                    onActivated: Bridge.setMode(currentText)
                }

                Repeater {
                    model: ["magick","tesseract","ffmpeg","n8n"]
                    delegate: Rectangle {
                        width: 10; height: 10; radius: 5
                        property string key: modelData
                        color: stateColor(root.statuses[key].state)
                        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true }
                        ToolTip {
                            visible: ma.containsMouse
                            text: root.statuses[key].version
                            padding: 6
                        }
                    }
                }

                Button { text: "Reload"; onClicked: { if (!Bridge.reloadActions()) toast.show("Reload failed", "error") } }
                Button {
                    id: ctBtn
                    text: root.ctState ? "Click-through: ON" : "Click-through: OFF"
                    onClicked: Bridge.toggleClickThrough()
                }
                Button {
                    id: kbBtn
                    text: "Ken Burns..."
                    visible: HasKenBurns
                    onClicked: kbDialog.open()
                }
                Button {
                    id: logBtn
                    text: logPanel.visible ? "Hide Log" : "Show Log"
                    onClicked: logPanel.visible = !logPanel.visible
                }
                Button { text: "Close"; onClicked: Qt.quit() }
            }
            MouseArea {
                anchors.fill: parent
                z: 999
                onPressed: root.startSystemMove()
            }
        }

        Flow {
            id: pinRow
            width: parent.width
            spacing: 4
            Repeater {
                id: repPinned
                model: Bridge.getPinned()
                delegate: Item {
                    width: 120; height: 32
                    Button {
                        id: pbtn
                        anchors.fill: parent
                        text: modelData.label
                        onClicked: { if (!Bridge.runAction(modelData.id)) toast.show("Action failed", "error") }
                    }
                    Row {
                        anchors.right: pbtn.right
                        anchors.top: pbtn.top
                        spacing: 2
                        Button { text:"◀"; onClicked: Bridge.movePinned(index, index-1) }
                        Button { text:"▶"; onClicked: Bridge.movePinned(index, index+1) }
                        Button { text:"✕"; onClicked: Bridge.unpinAction(modelData.id) }
                    }
                }
            }
        }

        Flow {
            id: actionsFlow
            width: parent.width
            spacing: 4
            Repeater {
                id: repAll
                model: Bridge.getActions()
                delegate: Item {
                    width: 140; height: 40
                    property bool pinned: Bridge.isPinned(modelData.id)
                    Button {
                        id: abtn
                        anchors.fill: parent
                        text: modelData.label
                        onClicked: { if (!Bridge.runAction(modelData.id)) toast.show("Action failed", "error") }
                    }
                    Button {
                        text: pinned ? "★" : "☆"
                        anchors.right: abtn.right
                        anchors.top: abtn.top
                        onClicked: pinned ? Bridge.unpinAction(modelData.id) : Bridge.pinAction(modelData.id)
                    }
                }
            }
        }
    }

    Rectangle {
        id: logPanel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 120
        visible: false
        color: "#101010"
        opacity: 0.8
        TextArea {
            id: logArea
            anchors.fill: parent
            readOnly: true
            color: "white"
        }
    }

    Rectangle {
        id: toast
        property string text: ""
        property string type: "info"
        property int timeout: 2000
        anchors.horizontalCenter: parent.horizontalCenter
        y: header.height + 8
        color: type === "error" ? "#E74C3C" : "#444444"
        radius: 4
        visible: opacity > 0
        opacity: 0
        z: 10
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Text { anchors.margins: 8; anchors.fill: parent; color: "white"; text: parent.text }
        Timer { id: toastTimer; interval: toast.timeout; onTriggered: toast.opacity = 0 }
        function show(msg, t) {
            text = msg; type = t || "info"; opacity = 1; toastTimer.restart();
        }
    }

    Dialog {
        id: kbDialog
        modal: true
        visible: false
        standardButtons: Dialog.Close
        onClosed: kbLoader.active = false
        Loader {
            id: kbLoader
            anchors.fill: parent
            active: visible && HasKenBurns
            source: HasKenBurns ? "plugins/kenburns/KenBurnsTab.qml" : ""
        }
    }

    Connections {
        target: Bridge
        function onActionsChanged() {
            repAll.model = Bridge.getActions();
            repPinned.model = Bridge.getPinned();
        }
        function onPinnedChanged() {
            repPinned.model = Bridge.getPinned();
            repAll.model = Bridge.getActions();
        }
        function onModeChanged() {
            modeBox.model = Bridge.getModes();
            var idx = modeBox.model.indexOf(Bridge.getMode());
            modeBox.currentIndex = idx >= 0 ? idx : 0;
        }
        function onStatusesChanged() {
            root.statuses = Bridge.getStatuses();
        }
        function onClickThroughChanged() {
            root.ctState = Bridge.getClickThrough();
            ctBtn.text = root.ctState ? "Click-through: ON" : "Click-through: OFF";
        }
        function onNotify(msg) {
            toast.show(msg, "info");
        }
        function onLog(text) {
            logLines.push(text);
            if (logLines.length > 200) logLines.shift();
            logArea.text = logLines.join('\n');
            logArea.cursorPosition = logArea.text.length;
        }
    }

}


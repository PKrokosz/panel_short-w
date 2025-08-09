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
    flags: Qt.FramelessWindowHint | Qt.Tool

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

    function stateColor(st) {
        if (st === "ok") return "#3ECF8E";
        if (st === "warn") return "#F5A623";
        if (st === "fail") return "#E74C3C";
        return "#7A7A7A";
    }

    Column {
        anchors.fill: parent
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
                    currentIndex: model.indexOf(Bridge.getMode())
                    onActivated: Bridge.setMode(currentText)
                }

                Repeater {
                    model: ["magick","tesseract","n8n"]
                    delegate: Rectangle {
                        width: 10; height: 10; radius: 5
                        property string key: modelData
                        color: stateColor(root.statuses[key].state)
                        ToolTip.visible: hovered
                        ToolTip.text: root.statuses[key].version
                        MouseArea { anchors.fill: parent; hoverEnabled: true }
                    }
                }
            }
        }

        Flow {
            id: pinRow
            width: parent.width
            spacing: 4
            Repeater {
                model: Bridge.getPinned()
                delegate: Item {
                    width: 120; height: 32
                    Button {
                        id: pbtn
                        anchors.fill: parent
                        text: modelData.label
                        onClicked: Bridge.runAction(modelData.id)
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
                model: Bridge.getActions()
                delegate: Item {
                    width: 140; height: 40
                    property bool pinned: Bridge.isPinned(modelData.id)
                    Button {
                        id: abtn
                        anchors.fill: parent
                        text: modelData.label
                        onClicked: Bridge.runAction(modelData.id)
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

    Connections {
        target: Bridge
        function onActionsChanged() {
            actionsFlow.model = Bridge.getActions();
            pinRow.model = Bridge.getPinned();
        }
        function onPinnedChanged() {
            pinRow.model = Bridge.getPinned();
            actionsFlow.model = Bridge.getActions();
        }
        function onModeChanged() {
            modeBox.model = Bridge.getModes();
            modeBox.currentIndex = modeBox.model.indexOf(Bridge.getMode());
        }
        function onStatusesChanged() {
            root.statuses = Bridge.getStatuses();
        }
    }
}


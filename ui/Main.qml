
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
  id: root
  visible: true
  width: 560; height: 240
  color: "transparent"
  flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

  MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton; onPressed: root.startSystemMove() }

  Rectangle { id: glass; anchors.fill: parent; radius: 20; color: "#1A1A1A"; opacity: 0.65; border.color: "#2A2A2A"; border.width: 1 }

  ColumnLayout {
    anchors.fill: parent; anchors.margins: 16; spacing: 10
    RowLayout {
      Layout.fillWidth: true; spacing: 8
      Label { text: "Overlay Router"; font.pixelSize: 18; color: "white" }
      Item { Layout.fillWidth: true }
      Button { text: "Reload"; onClicked: Bridge.reloadActions() }
      Button { text: "Click-through"; onClicked: Bridge.toggleClickThrough() }
      Button { text: "Close"; onClicked: Qt.quit() }
    }
    Flow {
      id: actionsFlow; Layout.fillWidth: true; Layout.preferredHeight: 100; spacing: 8
      Repeater {
        id: rep; model: Bridge.getActions()
        delegate: Button { text: modelData.label; implicitWidth: 150; onClicked: Bridge.runAction(modelData.id) }
      }
    }
    Rectangle { height: 1; color: "#444"; Layout.fillWidth: true }
    Flickable {
      Layout.fillWidth: true; Layout.fillHeight: true; contentWidth: logText.paintedWidth; contentHeight: logText.paintedHeight; clip: true
      TextArea { id: logText; readOnly: true; wrapMode: TextArea.Wrap; anchors.fill: parent; text: ""; color: "white" }
    }
  }
  Connections { target: Bridge
    function onLog(msg) { logText.append(msg) }
    function onNotify(msg) { logText.append("[INFO] " + msg) }
    function onActionsChanged() { rep.model = Bridge.getActions() }
  }
}

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

        RowLayout {
            Label { text: "Folder:" }
            TextField {
                id: folderField
                placeholderText: "."
                text: "."
                Layout.fillWidth: true
            }
            Button {
                text: "--help"
                ToolTip.text: "Wstaw --help do pola argów"
                onClicked: argField.text = "--help"
            }
        }

        RowLayout {
            spacing: 6
            Button { text: "Preview"; onClicked: argField.text = "--oneclick --profile preview" }
            Button { text: "Overlay Blur"; onClicked: argField.text = "--mode panels-overlay --bg-source blur --profile social" }
            Button { text: "Export Panels"; onClicked: argField.text = "--export-panels panels --export-mode rect" }
            Button {
                text: "Parametry…"
                onClicked: paramsDlg.open()
            }
        }

        TextField {
            id: argField
            placeholderText: "--help"
            Layout.fillWidth: true
        }

        // Dynamiczne parametry
        Loader {
            id: paramsLoader
            source: "plugins/kenburns/ParamsDialog.qml"
            active: true
            onLoaded: {
                item.schema = KenBurnsSchema
                item.ui = KenBurnsUi
            }
        }
        Component.onCompleted: {
            // nic — loader pasywny, używamy item przez id
        }
        function openParams() { paramsDlg.open() }
        property alias paramsDlg: paramsLoader.item

        RowLayout {
            Button {
                text: "Run"
                onClicked: {
                    const folder = (folderField.text || ".").trim();
                    const args = argField.text.trim();
                    const full = `"${folder.replace(/"/g, '\\"')}"` + (args ? " " + args : "");
                    KenBurns.run(full);
                }
            }
            Button {
                text: "Stop"
                onClicked: KenBurns.stop()
            }
            Button {
                text: "Save preset"
                onClicked: {
                    const ok = KenBurns.savePreset("custom_preset.json", argField.text);
                    toast.show(ok ? "Preset saved" : "Save failed", ok);
                }
            }
        }

        TextArea {
            id: logArea
            readOnly: true
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    // Obsługa powrotu z ParamsDialog (po OK)
    Connections {
        target: paramsDlg
        function onAccepted() {
            const s = paramsDlg.args || "";
            if (s && s.length) {
                // scal: stare argi + nowe (bez duplikacji folderu – folder jest poza dialogiem)
                argField.text = s;
                toast.show("Zastosowano parametry", true);
            }
        }
    }

    Connections {
        target: KenBurns
        function onOutput(msg) {
            logArea.append(msg)
            logArea.cursorPosition = logArea.length
        }
        function onFinished(code) {
            if (code === 0) toast.show("Process finished", true);
            else toast.show("Process failed (" + code + ")", false);
            logArea.append("[EXIT] " + code);
            logArea.cursorPosition = logArea.length;
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

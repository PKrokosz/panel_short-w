import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Dialog {
    id: dlg
    title: "Ken Burns — Parametry"
    standardButtons: Dialog.Ok | Dialog.Cancel
    modal: true
    property var schema: KenBurnsSchema || {}
    property var ui: KenBurnsUi || {}
    property var values: ({})      // bieżące wartości (flag→value)
    property string args: ""       // wynikowy ciąg

    width: 720; height: 520

    function _def(p)     { return p.default !== undefined ? p.default : (p.type==="bool" ? false : ""); }
    function _label(p)   { return (p.title || p.flag || p.key || "").replace(/^--?/, ""); }
    function _flag(p)    { return p.flag || ("--" + (p.key||"").replace(/^--/, "")); }
    function _isOn(p)    { return !!values[_flag(p)]; }

    // Konwersja wartości -> fragment CLI
    function _toArg(p, v) {
        const f = _flag(p);
        const t = (p.type||"string");
        const def = _def(p);
        // emituj tylko, gdy różni się od domyślnej (poza checkboxami zawsze-on)
        if (t === "bool")        return v ? f : "";
        if (v === "" || v === undefined || v === null) return "";
        if (JSON.stringify(v) === JSON.stringify(def)) return "";
        if (t === "enum")        return f + " " + v;
        if (t === "int" || t === "float") return f + " " + v;
        return f + " " + (/\s/.test(v) ? ('"'+v.replace(/"/g, '\\"')+'"') : v);
    }

    // Zbiór wszystkich parametrów (słownik flag → spec)
    function _specIndex() {
        const idx = {};
        if (schema && schema.params) {
            for (let i=0;i<schema.params.length;i++) {
                const p = schema.params[i];
                idx[_flag(p)] = p;
            }
        }
        return idx;
    }

    // zbuduj args z aktualnych kontrolek
    function buildArgs() {
        const idx = _specIndex();
        const acc = [];
        // iteruj po grupach z ui (zachowaj kolejność)
        const groups = (ui && ui.groups) ? ui.groups : [];
        for (let g=0; g<groups.length; g++) {
            const items = groups[g].items || [];
            for (let k=0;k<items.length;k++) {
                const key = items[k].flag || items[k].key;  // kompat
                const p = idx[key] || items[k];
                const v = values[_flag(p)];
                const s = _toArg(p, v);
                if (s) acc.push(s);
            }
        }
        args = acc.join(" ");
        return args;
    }

    contentItem: ScrollView {
        clip: true
        ColumnLayout {
            id: root
            spacing: 10
            padding: 10
            Repeater {
                model: (dlg.ui && dlg.ui.groups) ? dlg.ui.groups : []
                delegate: GroupBox {
                    required property var modelData
                    title: modelData.title || modelData.id || "Group"
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 8
                        Repeater {
                            model: modelData.items || []
                            delegate: RowLayout {
                                required property var modelData
                                property var spec: (function(){
                                    // połącz wpis z UI z wpisem w schema
                                    const F = modelData.flag || modelData.key;
                                    const list = (dlg.schema && dlg.schema.params) ? dlg.schema.params : [];
                                    for (let i=0;i<list.length;i++)
                                        if ((list[i].flag||list[i].key) === F) return Object.assign({}, list[i], modelData);
                                    return modelData;
                                })()
                                // label
                                Label { text: (spec.title || dlg._label(spec)); Layout.preferredWidth: 200 }
                                // kontrolka wg typu
                                Loader {
                                    id: ctl
                                    Layout.fillWidth: true
                                    sourceComponent: (function(){
                                        const t = (spec.type||"string");
                                        if (t === "bool")  return boolComp;
                                        if (spec.choices && spec.choices.length) return enumComp;
                                        if (t === "int" || t === "float") return numComp;
                                        return textComp;
                                    })()
                                }
                                // tooltip po najechaniu
                                ToolTip.visible: ma.containsMouse
                                ToolTip.text: spec.help || ""
                                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true }
                                // komponenty
                                Component {
                                    id: boolComp
                                    CheckBox {
                                        checked: (dlg.values[dlg._flag(spec)] !== undefined) ? dlg.values[dlg._flag(spec)] : dlg._def(spec)
                                        onToggled: dlg.values[dlg._flag(spec)] = checked
                                    }
                                }
                                Component {
                                    id: enumComp
                                    ComboBox {
                                        model: spec.choices
                                        currentIndex: Math.max(0, spec.choices.indexOf((dlg.values[dlg._flag(spec)] !== undefined) ? dlg.values[dlg._flag(spec)] : dlg._def(spec)))
                                        onActivated: dlg.values[dlg._flag(spec)] = currentText
                                    }
                                }
                                Component {
                                    id: numComp
                                    RowLayout {
                                        spacing: 6
                                        property real min: (spec.min !== undefined ? spec.min : 0)
                                        property real max: (spec.max !== undefined ? spec.max : 100)
                                        property real step: (spec.step !== undefined ? spec.step : 0.1)
                                        Slider {
                                            id: numSlider
                                            from: min; to: max; stepSize: step
                                            value: Number((dlg.values[dlg._flag(spec)] !== undefined) ? dlg.values[dlg._flag(spec)] : dlg._def(spec))
                                            Layout.preferredWidth: 200
                                            onValueChanged: dlg.values[dlg._flag(spec)] = (spec.type==="int" ? Math.round(value) : Number(value.toFixed(2)))
                                        }
                                        Label { text: (spec.type==="int" ? Math.round(numSlider.value).toString() : Number(numSlider.value).toFixed(2)) }
                                    }
                                }
                                    Component {
                                        id: textComp
                                        TextField {
                                            text: (dlg.values[dlg._flag(spec)] !== undefined) ? dlg.values[dlg._flag(spec)] : (dlg._def(spec) || "")
                                            placeholderText: spec.placeholder || ""
                                            onEditingFinished: dlg.values[dlg._flag(spec)] = text
                                        }
                                    }
                            }
                        }
                    }
                }
            }
        }
    }

    onAccepted: {
        buildArgs();
        dlg.close();
    }
}

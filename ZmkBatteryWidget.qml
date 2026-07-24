import QtQuick
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    property string keyboardName: pluginData.keyboardName || "Corne-ish Zen"
    property int refreshSeconds: Math.max(10, Number(pluginData.refreshInterval || 60))
    property int warningThreshold: Math.max(1, Math.min(99, Number(pluginData.warningThreshold || 20)))
    property string centralLabel: String(pluginData.centralLabel ?? "C").trim()
    property string peripheralLabel: String(pluginData.peripheralLabel ?? "P").trim()

    property int centralLevel: -1
    property int peripheralLevel: -1
    property bool isLoading: true
    property bool parsedOutput: false
    property string lastUpdated: ""
    property string errorText: ""
    property string scriptPath: PluginService.pluginDirectory + "/ZmkBattery/getBattery.sh"

    readonly property bool hasCentral: centralLevel >= 0
    readonly property bool hasPeripheral: peripheralLevel >= 0
    readonly property bool hasBattery: hasCentral || hasPeripheral
    readonly property int lowestLevel: {
        if (hasCentral && hasPeripheral)
            return Math.min(centralLevel, peripheralLevel);
        if (hasCentral)
            return centralLevel;
        if (hasPeripheral)
            return peripheralLevel;
        return -1;
    }
    readonly property color statusColor: batteryColor(lowestLevel)
    readonly property string centralText: hasCentral ? centralLevel + "%" : "--%"
    readonly property string peripheralText: hasPeripheral ? peripheralLevel + "%" : "--%"

    pillClickAction: () => refreshBattery()

    function batteryColor(level) {
        if (level < 0)
            return Theme.surfaceVariantText;
        if (level <= 10)
            return Theme.error;
        if (level <= warningThreshold)
            return Theme.warning;
        return Theme.primary;
    }

    function parseOutput(line) {
        var match = line.match(/^central:\s*(\d+|--)%\s+peripheral 0:\s*(\d+|--)%$/);
        if (!match)
            return;

        centralLevel = match[1] === "--" ? -1 : parseInt(match[1], 10);
        peripheralLevel = match[2] === "--" ? -1 : parseInt(match[2], 10);
        parsedOutput = true;
    }

    function refreshBattery() {
        if (batteryProcess.running)
            return;

        parsedOutput = false;
        errorText = "";
        isLoading = true;
        batteryProcess.running = true;
    }

    Process {
        id: batteryProcess

        command: ["bash", root.scriptPath, root.keyboardName]
        running: false

        stdout: SplitParser {
            onRead: data => root.parseOutput(data.trim())
        }

        stderr: SplitParser {
            onRead: data => {
                if (data.trim())
                    console.warn("[zmkBattery]", data.trim());
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.isLoading = false;

            if (exitCode !== 0 || !root.parsedOutput) {
                root.centralLevel = -1;
                root.peripheralLevel = -1;
                root.errorText = "Battery query failed";
                return;
            }

            if (!root.hasBattery)
                root.errorText = "Keyboard disconnected or battery services unavailable";

            root.lastUpdated = new Date().toLocaleTimeString(Qt.locale(), Locale.ShortFormat);
        }
    }

    Timer {
        id: refreshTimer

        interval: root.refreshSeconds * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshBattery()
    }

    Timer {
        id: settingsRefreshTimer

        interval: 100
        repeat: false
        onTriggered: root.refreshBattery()
    }

    Connections {
        target: pluginService
        enabled: pluginService !== null

        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId === root.pluginId)
                settingsRefreshTimer.restart();
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            DankIcon {
                name: root.isLoading ? "sync" : (root.hasBattery ? "keyboard" : "keyboard_off")
                size: root.iconSize
                color: root.isLoading ? Theme.surfaceVariantText : root.statusColor
                anchors.verticalCenter: parent.verticalCenter
            }

            Row {
                spacing: Theme.spacingXS
                anchors.verticalCenter: parent.verticalCenter

                StyledText {
                    visible: root.centralLabel.length > 0
                    text: root.centralLabel
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: root.isLoading && !root.hasBattery ? "…" : root.centralText
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                    color: root.batteryColor(root.centralLevel)
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: "·"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.outline
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    visible: root.peripheralLabel.length > 0
                    text: root.peripheralLabel
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: root.isLoading && !root.hasBattery ? "…" : root.peripheralText
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                    color: root.batteryColor(root.peripheralLevel)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.isLoading ? "sync" : (root.hasBattery ? "keyboard" : "keyboard_off")
                size: root.iconSize
                color: root.isLoading ? Theme.surfaceVariantText : root.statusColor
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Column {
                spacing: 1
                anchors.horizontalCenter: parent.horizontalCenter

                StyledText {
                    text: (root.centralLabel.length > 0 ? root.centralLabel + " " : "") +
                        (root.isLoading && !root.hasBattery ? "…" : root.centralText)
                    font.pixelSize: Math.max(8, Math.round(Theme.fontSizeSmall * 0.8))
                    font.weight: Font.DemiBold
                    color: root.batteryColor(root.centralLevel)
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                StyledText {
                    text: (root.peripheralLabel.length > 0 ? root.peripheralLabel + " " : "") +
                        (root.isLoading && !root.hasBattery ? "…" : root.peripheralText)
                    font.pixelSize: Math.max(8, Math.round(Theme.fontSizeSmall * 0.8))
                    font.weight: Font.DemiBold
                    color: root.batteryColor(root.peripheralLevel)
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}

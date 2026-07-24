import QtQuick
import Quickshell
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "zmkBattery"

    readonly property string discoverCommand: "bluetoothctl devices"
    readonly property string zmkBatteryGuideUrl: "https://zmk.dev/docs/config/battery"
    property bool discoverCommandCopied: false

    Timer {
        id: copiedReset
        interval: 1600
        onTriggered: root.discoverCommandCopied = false
    }

    StyledText {
        width: parent.width
        text: "ZMK Battery"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Displays the Battery Service values for the central half and ZMK's Peripheral 0 proxy. Click the bar widget to refresh immediately."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledText {
        width: parent.width
        text: "GATT setup required"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        textFormat: Text.RichText
        text: "The keyboard must be connected with its GATT services resolved. To expose both halves, enable peripheral battery fetching and proxying in ZMK. <a href=\"" + root.zmkBatteryGuideUrl + "\">Open the ZMK battery configuration guide</a>."
        linkColor: Theme.primary
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
        onLinkActivated: link => Qt.openUrlExternally(link)
    }

    StringSetting {
        settingKey: "keyboardName"
        label: "Keyboard name"
        description: "Exact Bluetooth name or alias shown by bluetoothctl"
        placeholder: "Corne-ish Zen"
        defaultValue: "Corne-ish Zen"
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StyledText {
        width: parent.width
        text: "Find your keyboard name"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Copy and paste this command into a terminal, then copy the name shown after your keyboard's Bluetooth address into the Keyboard name field above."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledRect {
        width: parent.width
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh
        implicitHeight: Math.max(discoverCommandText.implicitHeight, copyDiscoverCommandButton.height) + Theme.spacingS * 2

        StyledText {
            id: discoverCommandText
            anchors.left: parent.left
            anchors.right: copyDiscoverCommandButton.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Theme.spacingS
            anchors.rightMargin: Theme.spacingXS
            text: root.discoverCommand
            wrapMode: Text.WrapAnywhere
            color: Theme.primary
            font.pixelSize: Theme.fontSizeSmall - 1
            font.family: "monospace"
        }

        DankActionButton {
            id: copyDiscoverCommandButton
            anchors.right: parent.right
            anchors.rightMargin: Theme.spacingXS
            anchors.verticalCenter: parent.verticalCenter
            buttonSize: 28
            iconName: root.discoverCommandCopied ? "check" : "content_copy"
            iconColor: root.discoverCommandCopied ? Theme.success : Theme.surfaceVariantText
            backgroundColor: "transparent"
            tooltipText: root.discoverCommandCopied ? "Command copied" : "Copy command"
            onClicked: {
                Quickshell.execDetached([
                    "sh",
                    "-c",
                    "printf %s \"$1\" | wl-copy",
                    "_",
                    root.discoverCommand
                ]);
                root.discoverCommandCopied = true;
                copiedReset.restart();
            }
        }
    }

    SliderSetting {
        settingKey: "refreshInterval"
        label: "Refresh interval"
        description: "How often to query both keyboard halves"
        defaultValue: 60
        minimum: 10
        maximum: 600
        unit: "sec"
        leftIcon: "schedule"
    }

    SliderSetting {
        settingKey: "warningThreshold"
        label: "Low battery warning"
        description: "Use the warning color at or below this percentage"
        defaultValue: 20
        minimum: 5
        maximum: 50
        unit: "%"
        leftIcon: "battery_alert"
    }

    StringSetting {
        settingKey: "centralLabel"
        label: "Central label"
        description: "Name shown beside the central battery; leave empty to show only its percentage"
        placeholder: "No label"
        defaultValue: "central"
    }

    StringSetting {
        settingKey: "peripheralLabel"
        label: "Peripheral label"
        description: "Name shown beside Peripheral 0; leave empty to show only its percentage"
        placeholder: "No label"
        defaultValue: "peripheral 0"
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StyledText {
        width: parent.width
        text: "Requirements"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "The plugin uses BlueZ through busctl and requires bash and jq."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }
}

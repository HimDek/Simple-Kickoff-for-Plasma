/*
    SPDX-FileCopyrightText: 2014 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2020 Carl Schwan <carl@carlschwan.eu>
    SPDX-FileCopyrightText: 2021 Mikel Johnson <mikel5764@gmail.com>
    SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
    SPDX-FileCopyrightText: 2023 Himprakash Deka <himprakashd@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQml 2.15
import QtQuick.Layouts 1.15
import QtQuick.Templates 2.15 as T
import Qt5Compat.GraphicalEffects
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kirigamiaddons.components 1.0 as KirigamiComponents
import org.kde.coreaddons 1.0 as KCoreAddons
import org.kde.kcmutils as KCM
import org.kde.config as KConfig
import org.kde.plasma.plasmoid 2.0

EmptyPage {
    id: root

    property alias searchText: searchField.text
    readonly property alias leaveButtons: leaveButtons
    property real preferredSearchBarWidth: 0
    property Item pinButton: pinButton

    contentHeight: Math.max(searchField.implicitHeight, leaveButtons.implicitHeight)

    leftPadding: 0
    rightPadding: 0
    leftInset: -kickoff.backgroundMetrics.leftPadding
    rightInset: -kickoff.backgroundMetrics.rightPadding

    spacing: kickoff.backgroundMetrics.spacing

    function tabSetFocus(event, invertedTarget, normalTarget) {
        // Set input focus depending on whether layout order matches focus chain order
        // normalTarget is optional
        const reason = event.key == Qt.Key_Tab ? Qt.TabFocusReason : Qt.BacktabFocusReason
        if (kickoff.paneSwap) {
            invertedTarget.forceActiveFocus(reason)
        } else if (normalTarget !== undefined) {
            normalTarget.forceActiveFocus(reason)
        } else {
            event.accepted = false
        }
    }

    LeaveButtons {
        id: leaveButtons
        anchors.left: parent.left
        height: parent.height
        Keys.onLeftPressed:  event => {
            searchField.forceActiveFocus(Qt.TabFocusReason);
        }
        Keys.onRightPressed:  event => {
            searchField.forceActiveFocus(Qt.TabFocusReason);
        }
        Keys.onDownPressed: event => {
            if (plasmoid.rootItem.sideBar) {
                plasmoid.rootItem.sideBar.forceActiveFocus(Qt.TabFocusReason);
            } else {
                plasmoid.rootItem.contentArea.forceActiveFocus(Qt.TabFocusReason);
            }
        }
    }

    RowLayout {
        id: rowLayout
        spacing: root.spacing
        height: parent.height
        anchors.right: parent.right
        width: preferredSearchBarWidth
        Keys.onDownPressed: event => {
            kickoff.contentArea.forceActiveFocus(Qt.TabFocusReason);
        }
        LayoutMirroring.enabled: kickoff.sideBarOnRight

        PlasmaExtras.SearchField {
            id: searchField
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.leftMargin: kickoff.backgroundMetrics.leftPadding
            focus: true

            Binding {
                target: kickoff
                property: "searchField"
                value: searchField
                // there's only one header ever, so don't waste resources
                restoreMode: Binding.RestoreNone
            }
            Connections {
                target: kickoff
                function onExpandedChanged() {
                    if (kickoff.expanded) {
                        searchField.clear()
                    }
                }
            }
            onTextEdited: {
                searchField.forceActiveFocus(Qt.ShortcutFocusReason)
            }
            onAccepted: {
                kickoff.contentArea.currentItem.action.triggered()
                kickoff.contentArea.currentItem.forceActiveFocus(Qt.ShortcutFocusReason)
            }
            Keys.priority: Keys.AfterItem
            Keys.forwardTo: kickoff.contentArea !== null ? kickoff.contentArea.view : []
            Keys.onTabPressed: event => {
                tabSetFocus(event, nextItemInFocusChain(false));
            }
            Keys.onBacktabPressed: event => {
                tabSetFocus(event, nextItemInFocusChain());
            }
            Keys.onLeftPressed: event => {
                if (activeFocus) {
                    nextItemInFocusChain(kickoff.sideBarOnRight).forceActiveFocus(
                        Qt.application.layoutDirection === Qt.RightToLeft ? Qt.TabFocusReason : Qt.BacktabFocusReason)
                }
            }
            Keys.onRightPressed: event => {
                if (activeFocus) {
                    nextItemInFocusChain(!kickoff.sideBarOnRight).forceActiveFocus(
                        Qt.application.layoutDirection === Qt.RightToLeft ? Qt.BacktabFocusReason : Qt.TabFocusReason)
                }
            }
        }

        PC3.ToolButton {
            id: pinButton
            checkable: true
            checked: Plasmoid.configuration.pin
            icon.name: "window-pin"
            text: i18n("Keep Open")
            display: PC3.ToolButton.IconOnly
            PC3.ToolTip.text: text
            PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
            PC3.ToolTip.visible: hovered
            Binding {
                target: kickoff
                property: "hideOnWindowDeactivate"
                value: !Plasmoid.configuration.pin
                // there should be no other bindings, so don't waste resources
                restoreMode: Binding.RestoreNone
            }
            Keys.onTabPressed: event => {
                tabSetFocus(event, nextItemInFocusChain(false), kickoff.firstCentralPane || nextItemInFocusChain());
            }
            Keys.onBacktabPressed: event => {
                tabSetFocus(event, nameAndIcon.nextItemInFocusChain(false), nextItemInFocusChain(false));
            }
            Keys.onLeftPressed: event => {
                if (!kickoff.sideBarOnRight) {
                    nextItemInFocusChain(false).forceActiveFocus(Qt.application.layoutDirection == Qt.RightToLeft ? Qt.TabFocusReason : Qt.BacktabFocusReason)
                }
            }
            Keys.onRightPressed: event => {
                if (kickoff.sideBarOnRight) {
                    nextItemInFocusChain(false).forceActiveFocus(Qt.application.layoutDirection == Qt.RightToLeft ? Qt.BacktabFocusReason : Qt.TabFocusReason)
                }
            }
            onToggled: Plasmoid.configuration.pin = checked
        }
    }
}

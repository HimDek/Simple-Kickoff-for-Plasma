/*
 * SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
 * SPDX-FileCopyrightText: 2023 Himprakash Deka <himprakashd@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Templates 2.15 as T
import QtQml 2.15
import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasmoid 2.0

BasePage {
    id: root
    property real preferredSideBarWidth: 0
    property real stackViewWidth: contentAreaItem.width
    
    sideBarComponent: KickoffListView {
        id: sidebar
        focus: true
        model: kickoff.rootModel
        implicitWidth: root.preferredSideBarWidth + kickoff.backgroundMetrics.leftPadding + kickoff.backgroundMetrics.rightPadding
        // needed otherwise app displayed at top-level will show a first character as group.
        section.property: ""
        delegate: KickoffListDelegate {
            width: view.availableWidth
            isCategoryListItem: true
        }
    }

    contentAreaComponent: VerticalStackView {
        id: stackView
        popEnter: Transition {
            NumberAnimation {
                property: "x"
                from: 0.5 * root.width
                to: 0
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }

        pushEnter: Transition {
            NumberAnimation {
                property: "x"
                from: 0.5 * -root.width
                to: 0
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }

        readonly property string preferredFavoritesViewObjectName: Plasmoid.configuration.favoritesDisplay === 0 ? "favoritesGridView" : "favoritesListView"
        readonly property Component preferredFavoritesViewComponent: Plasmoid.configuration.favoritesDisplay === 0 ? favoritesGridViewComponent : favoritesListViewComponent
        readonly property string preferredAllAppsViewObjectName: Plasmoid.configuration.applicationsDisplay === 0 ? "listOfGridsView" : "applicationsListView"
        readonly property Component preferredAllAppsViewComponent: Plasmoid.configuration.applicationsDisplay === 0 ? listOfGridsViewComponent : applicationsListViewComponent
        readonly property string preferredAppsViewObjectName: Plasmoid.configuration.applicationsDisplay === 0 ? "applicationsGridView" : "applicationsListView"
        readonly property Component preferredAppsViewComponent: Plasmoid.configuration.applicationsDisplay === 0 ? applicationsGridViewComponent : applicationsListViewComponent
        // NOTE: The 0 index modelForRow isn't supposed to be used. That's just how it works.
        // But to trigger model data update, set initial value to 0
        property int appsModelRow: 0
        readonly property Kicker.AppsModel appsModel: kickoff.rootModel.modelForRow(appsModelRow)
        focus: true
        initialItem: preferredFavoritesViewComponent

        Component {
            id: favoritesListViewComponent
            DropAreaListView {
                id: favoritesListView
                objectName: "favoritesListView"
                mainContentView: true
                focus: true
                model: kickoff.rootModel.favoritesModel
            }
        }

        Component {
            id: favoritesGridViewComponent
            DropAreaGridView {
                id: favoritesGridView
                objectName: "favoritesGridView"
                focus: true
                model: kickoff.rootModel.favoritesModel
            }
        }

        Component {
            id: applicationsListViewComponent
            KickoffListView {
                id: applicationsListView
                objectName: "applicationsListView"
                mainContentView: true
                model: stackView.appsModel
                section.property: model && model.description === "KICKER_ALL_MODEL" ? "group" : ""
                section.criteria: ViewSection.FirstCharacter
            }
        }

        Component {
            id: applicationsGridViewComponent
            KickoffGridView {
                id: applicationsGridView
                objectName: "applicationsGridView"
                model: stackView.appsModel
                preferredHeight: root.implicitHeight
            }
        }

        onPreferredFavoritesViewComponentChanged: {
            if (root.sideBarItem !== null && root.sideBarItem.currentIndex === 0) {
                stackView.replace(stackView.preferredFavoritesViewComponent)
            }
        }
        onPreferredAppsViewComponentChanged: {
            if (root.sideBarItem !== null && root.sideBarItem.currentIndex > 1) {
                stackView.replace(stackView.preferredAppsViewComponent)
            }
        }

        Connections {
            target: root.sideBarItem
            function onCurrentIndexChanged() {
                // Only update row index if the condition is met.
                // The 0 index modelForRow isn't supposed to be used. That's just how it works.
                if (root.sideBarItem.currentIndex > 0) {
                    appsModelRow = root.sideBarItem.currentIndex
                }
                if (root.sideBarItem.currentIndex === 0
                    && stackView.currentItem.objectName !== stackView.preferredFavoritesViewObjectName) {
                    stackView.replace(stackView.preferredFavoritesViewComponent)
                } else if (root.sideBarItem.currentIndex === 1
                    && stackView.currentItem.objectName !== stackView.preferredAllAppsViewObjectName) {
                    stackView.replace(stackView.preferredAllAppsViewComponent)
                } else if (root.sideBarItem.currentIndex > 1
                    && stackView.currentItem.objectName !== stackView.preferredAppsViewObjectName) {
                    stackView.replace(stackView.preferredAppsViewComponent)
                }
            }
        }
        Connections {
            target: kickoff
            function onExpandedChanged() {
                if (kickoff.expanded) {
                    kickoff.contentArea.currentItem.forceActiveFocus()
                }
            }
        }
    }

    Binding {
        target: kickoff
        property: "sideBar"
        value: root.sideBarItem
        when: root.T.StackView.status === T.StackView.Active && root.visible
        restoreMode: Binding.RestoreBinding
    }
    Binding {
        target: kickoff
        property: "contentArea"
        value: root.contentAreaItem.currentItem // NOT just root.contentAreaItem
        when: root.T.StackView.status === T.StackView.Active && root.visible
        restoreMode: Binding.RestoreBinding
    }
}
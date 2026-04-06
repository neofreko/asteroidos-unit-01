/*
 * Copyright (C) 2026 - Gemini CLI
 * Based on Evangelion Unit-01 - Berserk Mode (Pixelify Edition)
 * Based on orbiting-asteroids by:
 *               2018 - Timo Könnecke <el-t-mo@arcor.de>
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, either version 2.1 of the
 * License, or (at your option) any later version.
 */

import QtQuick 2.1

Item {
    id: root
    anchors.fill: parent

    readonly property var radian: Math.PI / 180
    
    // Finalized artwork palette with neon yellow vibrancy
    readonly property color colorPurple: "#A020F0" // Electric Purple (Armor)
    readonly property color colorGreen: "#39FF14"  // Hyper Neon Green (Glow)
    readonly property color colorYellow: "#FFFF00" // Electric Yellow (Chest Highlights)
    readonly property color colorOrange: "#FF8C00" // Solar Orange (Energy)
    readonly property color colorRed: "#FF0000"    // Berserk Warning
    
    // Artwork Background
    readonly property color colorBgOuter: "#000000" // Pure Black
    readonly property color colorBgInner: "#2B0505" // Dark Maroon Glow

    // Unified "Breathing" Controller
    property real breathingFactor: 1.0
    SequentialAnimation on breathingFactor {
        running: !displayAmbient
        loops: Animation.Infinite
        NumberAnimation { from: 0.7; to: 1.0; duration: 2500; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1.0; to: 0.7; duration: 3500; easing.type: Easing.InOutSine }
    }

    // Load Pixelify Sans and other technical fonts
    FontLoader { id: pixelify; source: "../fonts/PixelifySans-Bold.ttf" }
    FontLoader { id: simpleness; source: "../fonts/Simpleness.otf" }

    // Background
    Rectangle {
        anchors.fill: parent
        color: colorBgOuter
    }

    // Atmosphere Glow
    Canvas {
        id: bgGlow
        anchors.fill: parent
        visible: !displayAmbient
        property real intensity: breathingFactor
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var grd = ctx.createRadialGradient(width/2, height/2, 0, width/2, height/2, width * 0.5 * intensity);
            grd.addColorStop(0, Qt.rgba(colorBgInner.r, colorBgInner.g, colorBgInner.b, 0.8 * intensity));
            grd.addColorStop(1, "transparent");
            ctx.fillStyle = grd;
            ctx.fillRect(0, 0, width, height);
        }
        onIntensityChanged: requestPaint()
    }

    // Static Corner Brackets
    Canvas {
        anchors.fill: parent
        visible: !displayAmbient
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.lineWidth = 1.5
            ctx.strokeStyle = Qt.rgba(colorYellow.r, colorYellow.g, colorYellow.b, 0.5 * breathingFactor)
            var bSize = width * 0.05; var margin = width * 0.08
            ctx.beginPath(); ctx.moveTo(margin, margin + bSize); ctx.lineTo(margin, margin); ctx.lineTo(margin + bSize, margin); ctx.stroke()
            ctx.beginPath(); ctx.moveTo(width-margin-bSize, margin); ctx.lineTo(width-margin, margin); ctx.lineTo(width-margin, margin+bSize); ctx.stroke()
            ctx.beginPath(); ctx.moveTo(margin, height-margin-bSize); ctx.lineTo(margin, height-margin); ctx.lineTo(margin+bSize, height-margin); ctx.stroke()
            ctx.beginPath(); ctx.moveTo(width-margin-bSize, height-margin); ctx.lineTo(width-margin, height-margin); ctx.lineTo(width-margin, height-margin-bSize); ctx.stroke()
        }
        onOpacityChanged: requestPaint()
    }

    // AT Field Core
    Canvas {
        id: hexagonCore
        width: parent.width * 0.42
        height: width
        anchors.centerIn: parent
        scale: 0.95 + (breathingFactor * 0.08)
        opacity: 0.6 + (breathingFactor * 0.4)
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var centerX = width / 2; var centerY = height / 2; var radius = width / 2 - 2
            ctx.beginPath()
            for (var i = 0; i < 6; i++) {
                var angle = (60 * i - 90) * radian; var x = centerX + radius * Math.cos(angle); var y = centerY + radius * Math.sin(angle)
                if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
            }
            ctx.closePath(); ctx.lineWidth = 3; ctx.strokeStyle = displayAmbient ? "white" : colorGreen; ctx.stroke()
            if (!displayAmbient) {
                ctx.fillStyle = Qt.rgba(colorPurple.r, colorPurple.g, colorPurple.b, 0.45); ctx.fill()
                ctx.beginPath(); ctx.moveTo(0, height * 0.3); ctx.lineTo(width, 0); ctx.lineTo(width, height * 0.2); ctx.lineTo(0, height * 0.5); ctx.closePath();
                ctx.fillStyle = Qt.rgba(1, 1, 1, 0.1); ctx.fill()
            }
        }
    }

    // Tactical Arcs (with isomorphic mirror — each arc is echoed 180° opposite)
    Canvas {
        id: tacticalCanvas
        anchors.fill: parent
        smooth: true
        renderStrategy: Canvas.Cooperative
        visible: !displayAmbient
        property var seconds: wallClock.time.getSeconds()
        property var minutes: wallClock.time.getMinutes()
        property var hours: wallClock.time.getHours()
        property real breath: breathingFactor
        onPaint: {
            var ctx = getContext("2d"); ctx.reset(); var centerX = width / 2; var centerY = height / 2
            var secAngle  = (seconds - 15) * 6
            var minAngle  = (minutes - 15) * 6
            var hourAngle = (hours % 12 - 3) * 30 + minutes * 0.5

            // Primary arcs
            drawGlossyArc(ctx, centerX, centerY, width * 0.47, secAngle,  colorGreen,  2, true,  1.0)
            drawGlossyArc(ctx, centerX, centerY, width * 0.41, minAngle,  colorPurple, 4, false, 1.0)
            drawGlossyArc(ctx, centerX, centerY, width * 0.35, hourAngle, colorYellow, 6, false, 1.0)

            // Isomorphic mirrors — same arcs reflected 180° opposite, at reduced opacity
            drawGlossyArc(ctx, centerX, centerY, width * 0.47, secAngle  + 180, colorGreen,  2, true,  0.35)
            drawGlossyArc(ctx, centerX, centerY, width * 0.41, minAngle  + 180, colorPurple, 4, false, 0.35)
            drawGlossyArc(ctx, centerX, centerY, width * 0.35, hourAngle + 180, colorYellow, 6, false, 0.35)
        }
        function drawGlossyArc(ctx, x, y, radius, angle, color, baseWidth, isSecond, opacityScale) {
            ctx.setLineDash(isSecond ? [2, 12] : [15, 6]); var startAngle = (angle - 25) * radian; var endAngle = (angle + 25) * radian
            ctx.beginPath(); ctx.arc(x, y, radius, startAngle - 0.2, endAngle + 0.2, false); ctx.lineWidth = baseWidth * 5 * breath; ctx.strokeStyle = Qt.rgba(color.r, color.g, color.b, 0.1 * breath * opacityScale); ctx.stroke()
            ctx.beginPath(); ctx.arc(x, y, radius, startAngle - 0.1, endAngle + 0.1, false); ctx.lineWidth = baseWidth * 3.5 * breath; ctx.strokeStyle = Qt.rgba(color.r, color.g, color.b, 0.35 * breath * opacityScale); ctx.stroke()
            ctx.beginPath(); ctx.arc(x, y, radius, startAngle, endAngle, false); ctx.lineWidth = baseWidth; ctx.strokeStyle = Qt.rgba(color.r, color.g, color.b, opacityScale); ctx.stroke()
            ctx.beginPath(); ctx.arc(x, y, radius - 1, startAngle + 0.05, endAngle - 0.05, false); ctx.lineWidth = 1.2; ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.9 * opacityScale); ctx.stroke()
            ctx.setLineDash([])
        }
        onBreathChanged: requestPaint()
    }

    // Ambient Indicators (with isomorphic mirrors)
    Canvas {
        id: ambientCanvas
        anchors.fill: parent
        visible: displayAmbient
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var centerX = width / 2; var centerY = height / 2
            ctx.lineWidth = 1; ctx.strokeStyle = "white"

            var minAngle  = (wallClock.time.getMinutes() - 15) * 6 * radian
            var hourAngle = ((wallClock.time.getHours() % 12 - 3) * 30 + wallClock.time.getMinutes() * 0.5) * radian

            // Primary dots
            ctx.beginPath(); ctx.arc(centerX + Math.cos(minAngle)*width*0.4,  centerY + Math.sin(minAngle)*width*0.4,  2, 0, 2*Math.PI); ctx.stroke()
            ctx.beginPath(); ctx.arc(centerX + Math.cos(hourAngle)*width*0.34, centerY + Math.sin(hourAngle)*width*0.34, 3, 0, 2*Math.PI); ctx.stroke()

            // Isomorphic mirror dots (180° opposite, half opacity)
            ctx.globalAlpha = 0.4
            ctx.beginPath(); ctx.arc(centerX - Math.cos(minAngle)*width*0.4,  centerY - Math.sin(minAngle)*width*0.4,  2, 0, 2*Math.PI); ctx.stroke()
            ctx.beginPath(); ctx.arc(centerX - Math.cos(hourAngle)*width*0.34, centerY - Math.sin(hourAngle)*width*0.34, 3, 0, 2*Math.PI); ctx.stroke()
            ctx.globalAlpha = 1.0
        }
    }

    // Metadata - Using Pixelify Sans for consistent pixel aesthetic
    Text {
        visible: !displayAmbient
        anchors.top: hexagonCore.bottom
        anchors.topMargin: parent.height * 0.03
        anchors.horizontalCenter: parent.horizontalCenter
        font.pixelSize: parent.height * 0.05
        font.family: pixelify.name
        color: colorGreen
        opacity: 0.6 + (breathingFactor * 0.4)
        text: "SYNC: 100%"
    }
    
    Text {
        visible: !displayAmbient
        anchors.bottom: hexagonCore.top
        anchors.bottomMargin: parent.height * 0.03
        anchors.horizontalCenter: parent.horizontalCenter
        font.pixelSize: parent.height * 0.05
        font.family: pixelify.name
        color: colorYellow 
        opacity: 0.6 + (breathingFactor * 0.4)
        text: "UNIT-01 ACTIVE"
    }

    // Digital Time Center - Pixelify Sans for that modern pixel feel
    Text {
        id: timeDisplay
        anchors.centerIn: parent
        font.pixelSize: parent.height * 0.14
        font.family: pixelify.name
        font.bold: true
        font.letterSpacing: 1
        color: "white"
        style: Text.Outline; styleColor: colorGreen
        text: wallClock.time.toLocaleString(Qt.locale(), use12H.value ? "h:mm" : "HH:mm")
    }

    // Isomorphic mirror of time — reflected vertically below center, faded
    Text {
        visible: !displayAmbient
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: timeDisplay.bottom
        anchors.topMargin: -timeDisplay.height * 0.1
        font.pixelSize: parent.height * 0.14
        font.family: pixelify.name
        font.bold: true
        font.letterSpacing: 1
        color: colorGreen
        opacity: 0.18
        transform: Scale { origin.x: timeDisplay.width / 2; origin.y: 0; yScale: -1 }
        text: wallClock.time.toLocaleString(Qt.locale(), use12H.value ? "h:mm" : "HH:mm")
    }

    Connections {
        target: desktop
        function onDisplayAmbientChanged() {
            if (displayAmbient) ambientCanvas.requestPaint()
            else { hexagonCore.requestPaint(); tacticalCanvas.requestPaint(); bgGlow.requestPaint() }
        }
    }

    Connections {
        target: wallClock
        function onTimeChanged() {
            if (!displayAmbient) {
                tacticalCanvas.seconds = wallClock.time.getSeconds(); tacticalCanvas.minutes = wallClock.time.getMinutes()
                tacticalCanvas.hours = wallClock.time.getHours(); tacticalCanvas.requestPaint()
            } else ambientCanvas.requestPaint()
        }
    }
}

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
import Nemo.Mce 1.0
import QtSensors 5.11
import org.asteroid.sensorlogd 1.0

Item {
    id: root
    anchors.fill: parent

    readonly property var radian: Math.PI / 180

    // Live sensor data
    property int  hrmBpm:   0
    property bool hrmActive: false
    property int  stepCount: 0

    // Palette sampled from EVA-01 reference image
    readonly property color colorPurple: "#a870c4" // Armor purple (sampled)
    readonly property color colorPurpleDark: "#541c54" // Deep armor shadow
    readonly property color colorGreen: "#8cc454"  // Visor / organic green (sampled)
    readonly property color colorYellow: "#e0a81c" // Warm gold — chest markings (sampled)
    readonly property color colorOrange: "#FF8C00" // Solar Orange (Energy)
    readonly property color colorRed: "#FF0000"    // Berserk Warning

    // Background — deep crimson-black from image bottom region
    readonly property color colorBgOuter: "#000000"
    readonly property color colorBgInner: "#380000"

    // Unified "Breathing" Controller
    property real breathingFactor: 1.0
    SequentialAnimation on breathingFactor {
        running: !displayAmbient
        loops: Animation.Infinite
        NumberAnimation { from: 0.7; to: 1.0; duration: 2500; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1.0; to: 0.7; duration: 3500; easing.type: Easing.InOutSine }
    }

    // Whole-surface contraction/expansion pulse
    transformOrigin: Item.Center
    property real pulseScale: 1.0
    SequentialAnimation on pulseScale {
        running: !displayAmbient
        loops: Animation.Infinite
        NumberAnimation { from: 0.97; to: 1.03; duration: 1800; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1.03; to: 0.97; duration: 2200; easing.type: Easing.InOutSine }
    }
    scale: pulseScale

    // Load fonts — NASDAQER for clock digits, ELEKTRA for labels
    FontLoader { id: nasdaqer; source: "../../fonts/NASDAQER_Fett.ttf" }
    FontLoader { id: elektra;  source: "../../fonts/ELEKTRA.ttf" }
    FontLoader { id: pixelify; source: "../../fonts/PixelifySans-Bold.ttf" }
    FontLoader { id: simpleness; source: "../../fonts/Simpleness.otf" }

    // Background
    Rectangle {
        anchors.fill: parent
        color: colorBgOuter
    }

    // AsteroidOS wallpaper motif — large logo slowly drifting/rotating in bg
    Image {
        id: bgLogoOuter
        source: "../watchfaces-img/asteroid-logo.svg"
        width: parent.width * 1.1
        height: width
        anchors.centerIn: parent
        opacity: 0.07
        visible: !displayAmbient
        transformOrigin: Item.Center
        RotationAnimation on rotation {
            from: 0; to: 360
            duration: 60000
            loops: Animation.Infinite
            running: !displayAmbient
        }
    }

    Image {
        id: bgLogoInner
        source: "../watchfaces-img/asteroid-logo.svg"
        width: parent.width * 0.55
        height: width
        anchors.centerIn: parent
        opacity: 0.10
        visible: !displayAmbient
        transformOrigin: Item.Center
        RotationAnimation on rotation {
            from: 360; to: 0
            duration: 38000
            loops: Animation.Infinite
            running: !displayAmbient
        }
    }


    Canvas {
        id: particleCanvas
        anchors.fill: parent
        visible: !displayAmbient

        property var particles: []
        property bool initialized: false

        function initParticles() {
            var count = 28
            particles = []
            for (var i = 0; i < count; i++) {
                particles.push({
                    x:     Math.random() * width,
                    y:     Math.random() * height,
                    r:     0.8 + Math.random() * 2.2,
                    speed: 0.18 + Math.random() * 0.38,
                    drift: (Math.random() - 0.5) * 0.25,
                    alpha: 0.1 + Math.random() * 0.5,
                    hue:   Math.random() < 0.6 ? "green" : "purple",
                    phase: Math.random() * Math.PI * 2
                })
            }
            initialized = true
        }

        Timer {
            id: particleTimer
            interval: 33
            running: !displayAmbient
            repeat: true
            onTriggered: {
                if (!particleCanvas.initialized) particleCanvas.initParticles()
                var ps = particleCanvas.particles
                for (var i = 0; i < ps.length; i++) {
                    ps[i].y     -= ps[i].speed
                    ps[i].x     += ps[i].drift
                    ps[i].phase += 0.03
                    ps[i].alpha  = 0.15 + 0.35 * Math.abs(Math.sin(ps[i].phase))
                    if (ps[i].y < -4) {
                        ps[i].y = particleCanvas.height + 2
                        ps[i].x = Math.random() * particleCanvas.width
                    }
                    if (ps[i].x < -4 || ps[i].x > particleCanvas.width + 4) {
                        ps[i].x = Math.random() * particleCanvas.width
                    }
                }
                particleCanvas.requestPaint()
            }
        }

        onPaint: {
            if (!initialized) return
            var ctx = getContext("2d")
            ctx.reset()
            for (var i = 0; i < particles.length; i++) {
                var p = particles[i]
                var col = p.hue === "green"
                    ? Qt.rgba(colorGreen.r,  colorGreen.g,  colorGreen.b,  p.alpha)
                    : Qt.rgba(colorPurple.r, colorPurple.g, colorPurple.b, p.alpha)
                // Soft glow halo
                var grd = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, p.r * 3.5)
                grd.addColorStop(0, col)
                grd.addColorStop(1, "transparent")
                ctx.fillStyle = grd
                ctx.beginPath()
                ctx.arc(p.x, p.y, p.r * 3.5, 0, 2 * Math.PI)
                ctx.fill()
                // Hard core
                ctx.fillStyle = col
                ctx.beginPath()
                ctx.arc(p.x, p.y, p.r, 0, 2 * Math.PI)
                ctx.fill()
            }
        }
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

    // EVA-01 motif: mono-eye visor, forehead horn, shoulder armor plates
    Canvas {
        id: evaMotifCanvas
        anchors.fill: parent
        visible: !displayAmbient
        property real breath: breathingFactor
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var cx = width / 2, cy = height / 2

            // --- Shoulder armor plates (left & right) ---
            function drawPlate(side) {
                var s = (side === "left") ? -1 : 1
                var px = cx + s * width * 0.42
                var py = cy - height * 0.06
                var pw = width * 0.10
                var ph = height * 0.22
                ctx.beginPath()
                ctx.moveTo(px,           py)
                ctx.lineTo(px + s*pw,    py - height*0.04)
                ctx.lineTo(px + s*pw,    py + ph + height*0.04)
                ctx.lineTo(px,           py + ph)
                ctx.closePath()
                ctx.fillStyle = Qt.rgba(colorPurpleDark.r, colorPurpleDark.g, colorPurpleDark.b, 0.55 * breath)
                ctx.fill()
                ctx.lineWidth = 1.5
                ctx.strokeStyle = Qt.rgba(colorPurple.r, colorPurple.g, colorPurple.b, 0.7 * breath)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(px,        py + ph * 0.38)
                ctx.lineTo(px + s*pw, py + ph * 0.34)
                ctx.lineWidth = 2
                ctx.strokeStyle = Qt.rgba(colorYellow.r, colorYellow.g, colorYellow.b, 0.6 * breath)
                ctx.stroke()
            }
            drawPlate("left")
            drawPlate("right")

            // --- Throat — segmented neck below visor, purple + green ring ---
            var throatTop = cy - height * 0.14
            var throatBot = cy - height * 0.01
            var throatW   = width * 0.09
            // body — tapers slightly from top to bottom
            ctx.beginPath()
            ctx.moveTo(cx - throatW,        throatTop)
            ctx.lineTo(cx + throatW,        throatTop)
            ctx.lineTo(cx + throatW * 0.75, throatBot)
            ctx.lineTo(cx - throatW * 0.75, throatBot)
            ctx.closePath()
            ctx.fillStyle = Qt.rgba(colorYellow.r, colorYellow.g, colorYellow.b, 0.80 * breath)
            ctx.fill()
            ctx.lineWidth = 1.2
            ctx.strokeStyle = Qt.rgba(colorYellow.r * 0.6, colorYellow.g * 0.6, colorYellow.b * 0.1, 0.9 * breath)
            ctx.stroke()
            // inner shadow on left face
            ctx.beginPath()
            ctx.moveTo(cx - throatW,        throatTop)
            ctx.lineTo(cx - throatW * 0.35, throatTop)
            ctx.lineTo(cx - throatW * 0.25, throatBot)
            ctx.lineTo(cx - throatW * 0.75, throatBot)
            ctx.closePath()
            ctx.fillStyle = Qt.rgba(colorYellow.r * 0.4, colorYellow.g * 0.4, 0, 0.5 * breath)
            ctx.fill()
            // segmentation crease line across middle
            var creaseY = throatTop + (throatBot - throatTop) * 0.45
            var creaseWTop = throatW * (1 - 0.45 * 0.25)
            ctx.beginPath()
            ctx.moveTo(cx - creaseWTop, creaseY)
            ctx.lineTo(cx + creaseWTop, creaseY)
            ctx.lineWidth = 1
            ctx.strokeStyle = Qt.rgba(colorYellow.r * 0.5, colorYellow.g * 0.5, 0, 0.7 * breath)
            ctx.stroke()
            // green ring near bottom of throat
            var tRingY = throatTop + (throatBot - throatTop) * 0.78
            var tRingW = throatW * 0.85
            ctx.beginPath()
            ctx.moveTo(cx - tRingW, tRingY)
            ctx.lineTo(cx + tRingW, tRingY)
            ctx.lineWidth = height * 0.012
            ctx.strokeStyle = Qt.rgba(colorGreen.r, colorGreen.g, colorGreen.b, 0.85 * breath)
            ctx.stroke()
            ctx.lineWidth = height * 0.025
            ctx.strokeStyle = Qt.rgba(colorGreen.r, colorGreen.g, colorGreen.b, 0.18 * breath)
            ctx.stroke()

            // --- Forehead horn — curved organic tusk, leans forward ---
            var hBaseY  = cy - height * 0.30   // wide base at head top
            var hBaseW  = width  * 0.13        // substantial base width
            var hTipX   = cx + width  * 0.03   // tip leans slightly forward (right)
            var hTipY   = cy - height * 0.47   // tip height
            var hMidX   = cx + width  * 0.05   // mid control point leans forward
            var hMidY   = cy - height * 0.39

            // right face of horn (outer curve)
            ctx.beginPath()
            ctx.moveTo(cx + hBaseW * 0.5,  hBaseY)
            ctx.quadraticCurveTo(hMidX + width*0.06,  hMidY, hTipX, hTipY)
            ctx.quadraticCurveTo(hMidX - width*0.04,  hMidY + height*0.01, cx - hBaseW * 0.5, hBaseY)
            ctx.closePath()
            ctx.fillStyle = Qt.rgba(colorPurple.r, colorPurple.g, colorPurple.b, 0.85 * breath)
            ctx.fill()

            // central spine ridge
            ctx.beginPath()
            ctx.moveTo(cx,               hBaseY)
            ctx.quadraticCurveTo(hMidX + width*0.01, hMidY, hTipX, hTipY)
            ctx.lineWidth = 2
            ctx.strokeStyle = Qt.rgba(colorPurpleDark.r, colorPurpleDark.g, colorPurpleDark.b, 0.7 * breath)
            ctx.stroke()

            // dark inner shadow — left face depth
            ctx.beginPath()
            ctx.moveTo(cx - hBaseW * 0.5, hBaseY)
            ctx.quadraticCurveTo(hMidX - width*0.06, hMidY + height*0.01, hTipX, hTipY)
            ctx.quadraticCurveTo(hMidX - width*0.01, hMidY, cx, hBaseY)
            ctx.closePath()
            ctx.fillStyle = Qt.rgba(colorPurpleDark.r, colorPurpleDark.g, colorPurpleDark.b, 0.55 * breath)
            ctx.fill()

            // green ring near base of horn
            var ringY = hBaseY - height * 0.025
            ctx.beginPath()
            ctx.moveTo(cx - hBaseW * 0.42, ringY)
            ctx.lineTo(cx + hBaseW * 0.42, ringY)
            ctx.lineWidth = height * 0.013
            ctx.strokeStyle = Qt.rgba(colorGreen.r, colorGreen.g, colorGreen.b, 0.85 * breath)
            ctx.stroke()
            // green ring glow
            ctx.lineWidth = height * 0.028
            ctx.strokeStyle = Qt.rgba(colorGreen.r, colorGreen.g, colorGreen.b, 0.2 * breath)
            ctx.stroke()

            // --- Mono-eye visor — angular "venom" shape with sharp edges ---
            var visY  = cy - height * 0.22
            var visW  = width * 0.26   // half-width to the sharp tip
            var visH  = height * 0.044 // half-height at the widest point
            // outer glow first
            var grd = ctx.createRadialGradient(cx, visY, 0, cx, visY, visW)
            grd.addColorStop(0.0, Qt.rgba(colorGreen.r, colorGreen.g, colorGreen.b, 0.45 * breath))
            grd.addColorStop(0.55, Qt.rgba(colorGreen.r, colorGreen.g, colorGreen.b, 0.12 * breath))
            grd.addColorStop(1.0, "transparent")
            ctx.fillStyle = grd
            ctx.beginPath()
            ctx.ellipse(cx - visW*1.15, visY - visH*2.8, visW*2.3, visH*5.6)
            ctx.fill()
            // Angular venom-eye path: sharp left/right tips, flat angled top/bottom edges
            function eyePath(rx, ry) {
                ctx.moveTo(cx - rx,         visY)               // left sharp tip
                ctx.lineTo(cx - rx*0.52,    visY - ry)          // upper-left edge
                ctx.lineTo(cx + rx*0.52,    visY - ry)          // upper-right edge
                ctx.lineTo(cx + rx,         visY)               // right sharp tip
                ctx.lineTo(cx + rx*0.52,    visY + ry)          // lower-right edge
                ctx.lineTo(cx - rx*0.52,    visY + ry)          // lower-left edge
                ctx.closePath()
            }
            // filled body
            ctx.beginPath(); eyePath(visW, visH)
            ctx.fillStyle = Qt.rgba(colorGreen.r, colorGreen.g, colorGreen.b, 0.6 * breath)
            ctx.fill()
            // hard outline
            ctx.beginPath(); eyePath(visW, visH)
            ctx.lineWidth = 1.8
            ctx.strokeStyle = Qt.rgba(colorGreen.r, colorGreen.g, colorGreen.b, 1.0 * breath)
            ctx.stroke()
            // inner lens — smaller hex-eye, brighter core
            ctx.beginPath(); eyePath(visW * 0.55, visH * 0.55)
            ctx.fillStyle = Qt.rgba(0.7, 1.0, 0.4, 0.45 * breath)
            ctx.fill()
            // specular glint — tiny bright slash near upper-left
            ctx.beginPath()
            ctx.moveTo(cx - visW*0.35, visY - visH*0.55)
            ctx.lineTo(cx - visW*0.08, visY - visH*0.65)
            ctx.lineWidth = 1.5
            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.55 * breath)
            ctx.stroke()
        }
        onBreathChanged: requestPaint()
        Component.onCompleted: requestPaint()
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

    // ── Live Sensor Components ──────────────────────────────────────────────
    MceBatteryLevel { id: batteryLevel }

    HrmSensor {
        active: !displayAmbient && hrmActive
        onReadingChanged: { root.hrmBpm = reading.bpm }
    }

    StepsDataLoader {
        id: stepsLoader
        Component.onCompleted: { stepsLoader.getTodayTotal(); root.stepCount = stepsLoader.todayTotal }
        onDataChanged:         { stepsLoader.getTodayTotal(); root.stepCount = stepsLoader.todayTotal }
    }

    // ── HUD Row (below clock) — Battery + Heart Rate ────────────────────────
    Row {
        visible: !displayAmbient
        anchors.top: hexagonCore.bottom
        anchors.topMargin: parent.height * 0.025
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: parent.width * 0.06

        // Battery → SYNC %
        Text {
            font.pixelSize: parent.parent.height * 0.047
            font.family: elektra.name
            color: {
                var p = batteryLevel.percent
                if (p <= 20) return colorRed
                if (p <= 50) return colorYellow
                return colorGreen
            }
            opacity: 0.6 + (breathingFactor * 0.4)
            text: "SYNC: " + batteryLevel.percent + "%"
        }

        // Heart Rate
        Text {
            font.pixelSize: parent.parent.height * 0.047
            font.family: elektra.name
            color: colorRed
            opacity: (hrmBpm > 0 ? 1.0 : 0.35) * (0.6 + breathingFactor * 0.4)
            text: "♥ " + (hrmBpm > 0 ? hrmBpm + " BPM" : "---")
            MouseArea {
                anchors.fill: parent
                onClicked: root.hrmActive = !root.hrmActive
            }
        }
    }

    // ── HUD Row (above clock) — Date + Steps ────────────────────────────────
    Row {
        visible: !displayAmbient
        anchors.bottom: hexagonCore.top
        anchors.bottomMargin: parent.height * 0.025
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: parent.width * 0.06

        // Date
        Text {
            font.pixelSize: parent.parent.height * 0.047
            font.family: elektra.name
            color: colorYellow
            opacity: 0.6 + (breathingFactor * 0.4)
            text: wallClock.time.toLocaleString(Qt.locale(), "ddd dd MMM").toUpperCase()
        }

        // Steps
        Text {
            font.pixelSize: parent.parent.height * 0.047
            font.family: elektra.name
            color: colorPurple
            opacity: 0.6 + (breathingFactor * 0.4)
            text: "⬡ " + (stepCount > 0 ? stepCount : "0")
        }
    }

    // Digital Time Center — NASDAQER for EVA HUD feel
    Text {
        id: timeDisplay
        anchors.centerIn: parent
        font.pixelSize: parent.height * 0.14
        font.family: nasdaqer.name
        font.bold: true
        font.letterSpacing: 2
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
        font.family: nasdaqer.name
        font.bold: true
        font.letterSpacing: 2
        color: colorGreen
        opacity: 0.18
        transform: Scale { origin.x: timeDisplay.width / 2; origin.y: 0; yScale: -1 }
        text: wallClock.time.toLocaleString(Qt.locale(), use12H.value ? "h:mm" : "HH:mm")
    }

    // ── Nightstand Mode ─────────────────────────────────────────────────────
    Item {
        id: nightstandMode
        readonly property bool active: nightstand
        anchors.fill: parent
        visible: nightstandMode.active

        // Deep crimson glow background
        Rectangle {
            anchors.fill: parent
            color: "#000000"
        }
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.7
            height: width
            radius: width / 2
            color: "transparent"
            layer.enabled: true
            layer.smooth: true
            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: width
                radius: width / 2
                color: colorBgInner
                opacity: 0.55
            }
        }

        // Segmented battery arc — purple segments filling clockwise
        Repeater {
            property real charge: batteryLevel.percent / 100
            property int  segments: 40
            property real stroke: 0.055
            property real scale: 0.44 - stroke / 2
            model: segments
            Rectangle {
                property real angle: -90 + (index / parent.segments) * 360
                property bool filled: (index / parent.segments) < parent.charge
                x: nightstandMode.width  / 2 + Math.cos(angle * Math.PI/180) * nightstandMode.width  * parent.scale - width/2
                y: nightstandMode.height / 2 + Math.sin(angle * Math.PI/180) * nightstandMode.height * parent.scale - height/2
                width:  nightstandMode.width  * parent.stroke * 0.6
                height: nightstandMode.height * parent.stroke
                radius: width / 2
                color: filled
                    ? (batteryLevel.percent <= 20 ? colorRed
                       : batteryLevel.percent <= 50 ? colorYellow
                       : colorGreen)
                    : "#1a1a2e"
                rotation: angle
                opacity: filled ? 0.9 : 0.3
            }
        }

        // Time display
        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -parent.height * 0.04
            font.pixelSize: parent.height * 0.18
            font.family: nasdaqer.name
            font.bold: true
            font.letterSpacing: 2
            color: "white"
            style: Text.Outline
            styleColor: colorGreen
            text: wallClock.time.toLocaleString(Qt.locale(), use12H.value ? "h:mm" : "HH:mm")
        }

        // UNIT-01 STANDBY label
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: parent.height * 0.18
            font.pixelSize: parent.height * 0.05
            font.family: elektra.name
            color: colorYellow
            opacity: 0.7
            text: "UNIT-01 STANDBY"
        }

        // SYNC % label
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: parent.height * 0.12
            font.pixelSize: parent.height * 0.045
            font.family: elektra.name
            color: batteryLevel.percent <= 20 ? colorRed
                 : batteryLevel.percent <= 50 ? colorYellow
                 : colorGreen
            opacity: 0.8
            text: "SYNC: " + batteryLevel.percent + "%"
        }
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

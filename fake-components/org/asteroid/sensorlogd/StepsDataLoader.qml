import QtQuick 2.9
import Nemo.Mce 1.0

Item {
    property int todayTotal: Global.steps
    signal dataChanged()

    function getTodayTotal() {
        todayTotal = Global.steps
    }

    Component.onCompleted: getTodayTotal()
}

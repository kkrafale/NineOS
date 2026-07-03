import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0d0d0d"
        }
        Image {
            source: "welcome.png"
            fillMode: Image.PreserveAspectFit
            anchors.fill: parent
            opacity: 0.3
        }
        Image {
            source: "logo.png"
            width: 120
            height: 120
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -40
            fillMode: Image.PreserveAspectFit
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 60
            text: "Instalando NineOS 1.0 Stone River..."
            color: "#ffffff"
            font.pixelSize: 20
            font.bold: true
        }
    }
}

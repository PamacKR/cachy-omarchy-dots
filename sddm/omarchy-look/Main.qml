import QtQuick 2.0
import SddmComponents 2.0

Rectangle {
  id: root
  width: 640
  height: 480
  // Templated by theme-set.sh (uses themes/<name>/colors.toml, not a
  // static color) - only takes effect after a theme switch re-copies this
  // file to /usr/share/sddm/themes/omarchy-look/, which needs sudo.
  color: "{{ background }}"

  // userModel.lastUser (and even userModel.data(userModel.index(0,0),...) as a
  // fallback) came back blank on a machine that had never had a successful
  // graphical login yet, silently authenticating as user "" no matter what
  // password was typed. This is a single-user machine, so just hardcode it -
  // change this if you ever add a second account.
  property string currentUser: "pamac"
  property bool loginFailed: false
  property int sessionIndex: {
    for (var i = 0; i < sessionModel.rowCount(); i++) {
      var name = (sessionModel.data(sessionModel.index(i, 0), Qt.DisplayRole) || "").toString()
      if (name.indexOf("niri") !== -1)
        return i
    }
    return sessionModel.lastIndex
  }

  Connections {
    target: sddm
    function onLoginFailed() {
      root.loginFailed = true
      password.text = ""
      password.focus = true
    }
    function onLoginSucceeded() {
      root.loginFailed = false
    }
  }

  Column {
    anchors.centerIn: parent
    spacing: 16

    Text {
      id: logo
      text: "PAMAC"
      font.bold: true
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 60
      font.letterSpacing: 5
      color: "{{ foreground }}"
      anchors.horizontalCenter: parent.horizontalCenter
    }

    // Only this wrapper is centered (same center line as the "PAMAC" text
    // above) - the lock icon hangs off its left edge instead of being part
    // of the centered group, so it doesn't pull the password box off-center.
    Item {
      id: entryWrapper
      anchors.horizontalCenter: parent.horizontalCenter
      width: entry.width
      height: entry.height

      Image {
        id: entry
        source: root.loginFailed ? "entry-failed.png" : "entry.png"
        anchors.centerIn: parent
      }

      Row {
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Repeater {
          model: Math.min(password.text.length, 21)

          Image {
            source: "bullet.png"
            width: 7
            height: 7
          }
        }
      }

      TextInput {
        id: password
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        verticalAlignment: TextInput.AlignVCenter
        echoMode: TextInput.Password
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 24
        font.letterSpacing: 5
        passwordCharacter: "•"
        color: "transparent"
        selectionColor: "transparent"
        selectedTextColor: "transparent"
        cursorDelegate: Item {}
        focus: true

        onTextChanged: root.loginFailed = false

        Keys.onPressed: {
          if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            sddm.login(root.currentUser, password.text, root.sessionIndex)
            event.accepted = true
          }
        }
      }

      // Positioned outside entryWrapper's own bounds (QML doesn't clip
      // children by default), so it doesn't affect entryWrapper's centering.
      Image {
        source: root.loginFailed ? "lock-failed.png" : "lock.png"
        width: 34
        height: 38
        fillMode: Image.PreserveAspectFit
        anchors.right: parent.left
        anchors.rightMargin: 15
        anchors.verticalCenter: parent.verticalCenter
      }
    }

  }

  Component.onCompleted: password.forceActiveFocus()
}

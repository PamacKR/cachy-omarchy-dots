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
    //
    // Drawn with plain QML shapes (Rectangle/Text) rather than the original
    // Omarchy PNG assets (entry.png/lock.png/bullet.png) - those had the
    // tokyo-night blue baked into the actual pixels, so they never picked up
    // theme-set.sh's color substitution and stayed blue regardless of theme.
    Item {
      id: entryWrapper
      anchors.horizontalCenter: parent.horizontalCenter
      width: 286
      height: 48

      Rectangle {
        id: entry
        anchors.fill: parent
        radius: 0
        color: "transparent"
        border.width: 2
        border.color: root.loginFailed ? "{{ color1 }}" : "{{ foreground }}"
      }

      Row {
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Repeater {
          model: Math.min(password.text.length, 21)

          Rectangle {
            width: 8
            height: 8
            radius: 4
            color: "{{ foreground }}"
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
      Text {
        text: "󰌾"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 26
        color: root.loginFailed ? "{{ color1 }}" : "{{ foreground }}"
        anchors.right: parent.left
        anchors.rightMargin: 15
        anchors.verticalCenter: parent.verticalCenter
      }
    }

  }

  Component.onCompleted: password.forceActiveFocus()
}

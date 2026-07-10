import QtQuick 2.0
import SddmComponents 2.0

Rectangle {
  id: root
  width: 640
  height: 480
  color: "#1a1b26"

  // userModel.lastUser (and even userModel.data(userModel.index(0,0),...) as a
  // fallback) came back blank on a machine that had never had a successful
  // graphical login yet, silently authenticating as user "" no matter what
  // password was typed. This is a single-user machine, so just hardcode it -
  // change this if you ever add a second account.
  property string currentUser: "pamac"
  property bool loginFailed: false
  // Set on a successful password check, before the session actually starts.
  // The greeter keeps rendering full-screen until SDDM switches the VT over
  // to the compositor, so a looping bar shown for that whole window hides
  // the grey/blank gap that otherwise shows while niri+DMS are starting up.
  property bool loggingIn: false
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
      root.loggingIn = false
      password.text = ""
      password.focus = true
    }
    function onLoginSucceeded() {
      root.loginFailed = false
      root.loggingIn = true
    }
  }

  Column {
    anchors.centerIn: parent
    spacing: 40

    Text {
      id: logo
      text: "PAMAC"
      font.bold: true
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 40
      font.letterSpacing: 6
      color: "#a9b1d6"
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
        visible: !root.loggingIn
      }

      Row {
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5
        visible: !root.loggingIn

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
        visible: !root.loggingIn
        enabled: !root.loggingIn

        onTextChanged: root.loginFailed = false

        Keys.onPressed: {
          if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            // Show the loading bar immediately, before the (async) login
            // result comes back - sddm.login() replies via onLoginSucceeded/
            // onLoginFailed, and by the time that round-trip completes SDDM
            // may already be tearing the greeter down, leaving no frame left
            // to render a state change triggered from the signal handler.
            root.loggingIn = true
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
        visible: !root.loggingIn
      }

      // Thin indeterminate loading bar, swapped in for the password box on a
      // successful login - same footprint/position as the entry field so
      // nothing else in the layout shifts.
      Rectangle {
        id: loadingTrack
        anchors.centerIn: parent
        width: parent.width - 40
        height: 3
        radius: 1.5
        color: "#33414868"
        visible: root.loggingIn
      }

      Rectangle {
        id: loadingIndicator
        y: loadingTrack.y
        width: loadingTrack.width * 0.35
        height: 3
        radius: 1.5
        color: "#7aa2f7"
        visible: root.loggingIn

        SequentialAnimation on x {
          running: root.loggingIn
          loops: Animation.Infinite
          NumberAnimation {
            from: loadingTrack.x - loadingIndicator.width
            to: loadingTrack.x + loadingTrack.width
            duration: 1100
            easing.type: Easing.InOutQuad
          }
        }
      }
    }

  }

  Component.onCompleted: password.forceActiveFocus()
}

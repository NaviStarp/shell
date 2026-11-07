pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: service

    // ==========================================
    // SWAY WORKSPACE STATE
    // ==========================================
    property var workspaces: []
    property string activeWorkspaceName: "1"
    property string focusedOutputName: ""
    property var activeWorkspaceByOutput: ({})
    property string _wsBuffer: ""
    property bool _wsUpdatePending: false

    function updateWorkspaces() {
        if (!getWsProc.running) {
            service._wsBuffer = "";
            getWsProc.running = true;
        } else {
            service._wsUpdatePending = true;
        }
    }

    function switchWorkspace(name) {
        service.activeWorkspaceName = name;
        if (service.focusedOutputName !== "") {
            var copy = Object.assign({}, service.activeWorkspaceByOutput);
            copy[service.focusedOutputName] = name;
            service.activeWorkspaceByOutput = copy;
        }
        swayExec.command = ["swaymsg", "workspace", name];
        swayExec.running = true;
    }

    function exec(cmd) {
        sysAction.exec(cmd);
    }

    // Process to query workspaces safely with buffer accumulation
    Process {
        id: getWsProc
        command: ["swaymsg", "-t", "get_workspaces", "-r"]

        onRunningChanged: {
            if (!running) {
                if (service._wsBuffer.length > 0) {
                    var rawJson = service._wsBuffer.trim();
                    service._wsBuffer = "";

                    try {
                        var data = JSON.parse(rawJson);
                        if (Array.isArray(data)) {
                            var byOut = {};
                            for (var i = 0; i < data.length; i++) {
                                if (data[i].visible) {
                                    byOut[data[i].output] = data[i].name;
                                }
                                if (data[i].focused) {
                                    service.activeWorkspaceName = data[i].name;
                                    service.focusedOutputName = data[i].output;
                                    byOut[data[i].output] = data[i].name;
                                }
                            }
                            service.activeWorkspaceByOutput = byOut;

                            // Only replace array if structure changed to prevent delegate destruction
                            var listChanged = false;
                            if (data.length !== service.workspaces.length) {
                                listChanged = true;
                            } else {
                                for (var j = 0; j < data.length; j++) {
                                    if (data[j].name !== service.workspaces[j].name || data[j].output !== service.workspaces[j].output) {
                                        listChanged = true;
                                        break;
                                    }
                                }
                            }
                            if (listChanged) {
                                service.workspaces = data.slice();
                            }
                        }
                    } catch(e) {}
                }

                if (service._wsUpdatePending) {
                    service._wsUpdatePending = false;
                    service.updateWorkspaces();
                }
            }
        }

        stdout: SplitParser {
            splitMarker: ""
            onRead: chunk => {
                if (chunk) service._wsBuffer += chunk;
            }
        }
    }

    // Continuous workspace event stream (0ms latency for focus changes)
    Process {
        id: swayEventsStream
        command: ["swaymsg", "-m", "-r", "-t", "subscribe", "[\"workspace\"]"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (line.trim().length > 0) {
                    try {
                        var ev = JSON.parse(line.trim());
                        if (ev && ev.change === "focus" && ev.current && ev.current.name) {
                            service.activeWorkspaceName = ev.current.name;
                            if (ev.current.output) {
                                service.focusedOutputName = ev.current.output;
                                var copy = Object.assign({}, service.activeWorkspaceByOutput);
                                copy[ev.current.output] = ev.current.name;
                                service.activeWorkspaceByOutput = copy;
                            }
                        }
                    } catch(e) {}
                    service.updateWorkspaces();
                }
            }
        }
    }

    // Command runner for switching workspaces
    Process {
        id: swayExec
    }

    // Generic system command runner
    Process {
        id: sysAction
        function exec(cmd) {
            command = ["sh", "-c", cmd];
            running = true;
        }
    }

    Component.onCompleted: {
        updateWorkspaces();
    }
}

import QtQuick
import qs.Common

QtObject {
    function check(done) {
        Proc.runCommand(
            "zmkBattery.dependencies",
            ["which", "bash", "busctl", "jq"],
            (stdout, exitCode) => {
                if (exitCode === 0) {
                    done(null);
                    return;
                }

                done({
                    title: "ZmkBattery dependencies are missing",
                    details: "Install bash, systemd (for busctl), and jq, then enable the plugin again."
                });
            }
        );
    }
}

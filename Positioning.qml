import QtQuick 2.0
import QtPositioning 5.13

PositionSource {
    id: positionSource
    updateInterval: 1000
//        active: true
    // nmeaSource: "SpecialDelivery2.nmea"

    function logPosition(position) {
        console.log("-> positionSource.nmeaSource", positionSource.nmeaSource)
        console.log("positionSource.method", printableMethod(positionSource.supportedPositioningMethods))
        console.log("position.timestamp", position.timestamp)
        console.log("position.coordinate.longitude", position.coordinate.longitude)
        console.log("position.coordinate.latitude", position.coordinate.latitude)
        console.log("position.coordinate.altitude", position.coordinate.altitude)
        console.log("position.coordinate.isValid", position.coordinate.isValid)
        console.log("position.altitudeValid", position.altitudeValid)
        console.log("position.direction", position.direction)
        console.log("position.directionValid", position.directionValid)
        console.log("position.horizontalAccuracy", position.horizontalAccuracy)
        console.log("position.horizontalAccuracyValid", position.horizontalAccuracyValid)
        console.log("position.latitudeValid", position.latitudeValid)
        console.log("position.longitudeValid", position.longitudeValid)
        console.log("position.magneticVariation", position.magneticVariation)
        console.log("position.magneticVariationValid", position.magneticVariationValid)
        console.log("position.speed", position.speed)
        console.log("position.speedValid", position.speedValid)
        console.log("position.verticalAccuracy", position.verticalAccuracy)
        console.log("position.verticalAccuracyValid", position.verticalAccuracyValid)
        console.log("position.verticalSpeed", position.verticalSpeed)
        console.log("position.verticalSpeedValid", position.verticalSpeedValid)
    }

    onPositionChanged: {
        var stat = "info";
        var statT = "GPS: OK";


        if (positionSource.position && positionSource.position.coordinate.isValid) {

            // Save valid updated position.
            var savedRowId = saveValidPosition(positionSource.position);
            if (savedRowId) {
                // logPosition(positionSource.position);

                // Push (all, recursively) to API at simply batched intervals.
                if (savedRowId % window.pushBatchEvery === 0) {
                    pushBatching(window.pushBatchSize);
                }

            } else {
                statT = "DB: save failed";
                stat = "error"
            }
        } else {
            statT = "GPS: invalid position";
            stat = "error"
        }
        setStatusDisplay(gpsStatusText, stat, statT);
    }

    onSourceErrorChanged: {
        if (sourceError == PositionSource.NoError)
            return
        setStatusDisplay(gpsStatusText, "error", sourceError)
        stop()
    }
    onUpdateTimeout: {
        setStatusDisplay(gpsStatusText, "warn", "update timed out");
    }
}

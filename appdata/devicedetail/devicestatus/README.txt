Place device status JSON files here.

Device status includes
- Connectivity status (bluetooth, wifi, cellular)
- Power sources status
- Generic status of device

=====================
 Connectivity Status
=====================

JSON Requirement:
- Status files are written when status is updated. New status should always overwrite the old status file so only the latest status is read.
- Connectivity properties are arbitrary key-values. Keys (like "Prop1" below) are strings. Values contains a string representation of 
  the value and the data type of the data. Refer to Device Detail documentation for a complete list of supported data type.
- Timestamp field must be in RFC3399 format (https://www.ietf.org/rfc/rfc3339.txt) and default to the epoch time if not specified.

Example bluetooth status:
{
    "bluetoothStatus": [
        {
            "enabled": true,
            "connected": true,
            "profile": "PAN",
            "connectedDevice": "iotNetwork"
        },
        {
            "enabled": true,
            "connected": true,
            "profile": "HID",
            "connectedDevice": "wirelessKeyboard"
        },
        {
            "enabled": true,
            "connected": true,
            "profile": "HID",
            "connectedDevice": "wirelessMouse",
            "attributes": {
                "Manufacturer": {
                    "value": "Logitech",
                    "dataType": "DATATYPE_STRING"
                },
                "Color": {
                    "value": "Pink",
                    "dataType": "DATATYPE_STRING"
                }
            }
        }
    ]
}

Example wifi status:
{
    "wifiStatus": [
        {
            "enabled": true,
            "connected": true,
            "ssid": "iotNetwork1",
            "attributes": {
                "Network key": {
                    "value": "D0D0DEADF00DABBADEAFBEADED",
                    "dataType": "DATATYPE_STRING"
                }
            }
        },
        {
            "enabled": true,
            "connected": false,
            "ssid": "iotNetwork2"
        }
    ]
}

Example cellular status:
{
    "cellularStatus": [
        {
            "id": "cell_1",
            "networkMode": "CDMA",
            "dataVolume": 0,
            "signalStrength": {
                "rssi": -55
            }
        },
        {
            "id": "cell_2",
            "networkMode": "LTE",
            "dataVolume": 18446744073709551615,
            "signalStrength": {
                "rssi": -100
            },
            "attributes": {
                "MCC": {
                    "value": "310",
                    "dataType": "DATATYPE_INT"
                },
                "MNC": {
                    "value": "410",
                    "dataType": "DATATYPE_INT"
                },
                "Carrier": {
                    "value": "AT&T"
                }
            }
        },
        {
            "id": "490154203237512",
            "networkMode": "LTE",
            "dataVolume": 132000,
            "signalStrength": {
                "sinr": 29,
                "rsrp": -86,
                "ecio": 0,
                "rssi": -55,
                "rscp": 0,
                "rsrq": -6
            }
        }
    ]
}

=====================
 Power Source Status
=====================

JSON Requirement:
- Status files are written when status is updated. New status should always overwrite the old status file so only the latest status is read.
- Set percentageFull to -1 if it is not applicable to the power source.
- Power source properties are arbitrary key-values. Keys (like "Prop1" below) are strings. Values contains a string representation of 
  the value and the data type of the data. Refer to Device Detail documentation for a complete list of supported data type.
- Timestamp field must be in RFC3399 format (https://www.ietf.org/rfc/rfc3339.txt) and default to the epoch time if not specified.

Example power supply status:
{
    "powerSupplyStatus": [
        {
            "type": "AC",
            "state": "OK",
            "percentageFull": -1,
            "description": "Everything looks good."
        },
        {
            "type": "Battery",
            "state": "Discharging",
            "percentageFull": 30,
            "description": "Battery low!!!",
            "attributes": {
                "Estimated time remaining (minutes)": {
                    "value": "40",
                    "dataType": "DATATYPE_INT"
                },
                "isPlugged": {
                    "value": "false",
                    "dataType": "DATATYPE_BOOLEAN"
                }
            }
        },
        {
            "type": "UPS",
            "state": "FAULTY",
            "percentageFull": -1,
            "description": "Attention needed."
        }
    ]
}

================
 Generic Status
================

JSON Requirement:
- Status files are written when status is updated. New status should always overwrite the old status file so only the latest status is read.
- Properties should always contain the full set of properties. Edge Manager services replace the old information with the new.
- Properties are arbitrary key-values. Keys (like "Prop1" below) are strings. Values contains a string representation of the value
  and the data type of the data. Refer to Device Detail documentation for a complete list of supported data type.
- Timestamp field must be in RFC3399 format (https://www.ietf.org/rfc/rfc3339.txt) and default to the epoch time if not specified. See examples below.

Example device status properties:
{
    "attributes": {
        "Prop2": {
            "value": "2147483647",
            "dataType": "DATATYPE_INT"
        },
        "Prop1": {
            "value": "This is a string",
            "dataType": "DATATYPE_STRING"
        },
        "Prop7": {
            "value": "false",
            "dataType": "DATATYPE_BOOLEAN"
        },
        "Prop8": {
            "value": "XDFDSLKFIERTW*EGJ$%($%*HFKDF",
            "dataType": "DATATYPE_BINARY"
        },
        "Prop9": {
            "value": "2016-10-25T03:54:43.230Z",
            "dataType": "DATATYPE_TIMESTAMP"
        },
        "Prop3": {
            "value": "9223372036854775807",
            "dataType": "DATATYPE_LONG"
        },
        "Prop4": {
            "value": "1.7976931348623157E308",
            "dataType": "DATATYPE_DOUBLE"
        },
        "Prop5": {
            "value": "3.4028235E38",
            "dataType": "DATATYPE_FLOAT"
        },
        "Prop6": {
            "value": "true",
            "dataType": "DATATYPE_BOOLEAN"
        }
    }
}

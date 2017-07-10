Place device information JSON files here.

Device information includes
- Hardware information
- SIM information
- Generic information of device

======================
 Hardware Information
======================

JSON Requirement:
- HardwareInfo should always contain the full set of hardware. Edge Manager services replace the old information with the new.
- HardwareInfo properties are arbitrary key-value pairs. Both key and value must be strings.
- Other fields (category, manufacturer, model, etc) are defined fields.

Example hardware info:
{
    "hardwareInfo": [
        {
            "category": "cpu",
            "manufacturer": "ABC Inc.",
            "model": "CPU123",
            "firmware": "1.1.1",
            "attributes": {
                "numberOfProcessors": {
                    "value": "1",
                    "dataType": "DATATYPE_INT"
                },
                "frequency": {
                    "value": "1GHz"
                },
                "numberOfCores": {
                    "value": "2",
                    "dataType": "DATATYPE_INT"
                }
            }
        },
        {
            "category": "modem",
            "manufacturer": "Netgear",
            "model": "101",
            "firmware": "1.2.3"
        },
        {
            "category": "ups",
            "manufacturer": "Controlled Power Company",
            "model": "LT700",
            "firmware": "1.1.1",
            "attributes": {
                "Detail": {
                    "value": "http://www.controlledpwr.com/brochureFiles/35/LTSeriesBrochure.pdf"
                },
                "Full load runtimes": {
                    "value": "11.5 min"
                },
                "Weight": {
                    "value": "70 lbs"
                },
                "VA": {
                    "value": "700",
                    "dataType": "DATATYPE_INT"
                },
                "Dimensions": {
                    "value": "8.125\" W x 17.5\" D x 17.5\" H"
                },
                "Half load runtimes": {
                    "value": "30 min"
                },
                "WATTS": {
                    "value": "500",
                    "dataType": "DATATYPE_INT"
                },
                "BTU's/Hour": {
                    "value": "256",
                    "dataType": "DATATYPE_INT"
                }
            }
        },
        {
            "category": "memory",
            "manufacturer": "Kingston",
            "model": "HyperX FURY",
            "attributes": {
                "Detail": {
                    "value": "http://media.kingston.com/pdfs/HyperX_FURY_DDR3_US.pdf"
                },
                "Speed": {
                    "value": "1866MHz"
                },
                "Storage Temperature": {
                    "value": "-55C to 100C"
                },
                "Type": {
                    "value": "DDR3"
                },
                "Dimensions": {
                    "value": "133.35mm x 32.8mm"
                },
                "Voltage": {
                    "value": "1.35V"
                },
                "Capacity": {
                    "value": "8GB"
                },
                "Operating Temperature": {
                    "value": "0C to 85C"
                }
            }
        },
        {
            "category": "memory",
            "manufacturer": "Samsung",
            "model": "generic",
            "attributes": {
                "Speed": {
                    "value": "1333MHz"
                },
                "Type": {
                    "value": "DDR3"
                },
                "Voltage": {
                    "value": "1.35V"
                },
                "Capacity": {
                    "value": "8GB"
                },
                "Part Numbers": {
                    "value": "M393B1K70CH0-YH9, M393B1K70DH0-YH9"
                }
            }
        },
        {
            "category": "cpu164",
            "manufacturer": "ABC Inc.",
            "model": "CPU123",
            "firmware": "1.1.1",
            "properties": {
                "numberOfProcessors": "1",
                "frequency": "1GHz",
                "numberOfCores": "2"
            }
        },
        {
            "category": "modem164",
            "manufacturer": "Netgear",
            "model": "101",
            "firmware": "1.2.3"
        },
        {
            "category": "ups164",
            "manufacturer": "Controlled Power Company",
            "model": "LT700",
            "firmware": "1.1.1",
            "properties": {
                "Detail": "http://www.controlledpwr.com/brochureFiles/35/LTSeriesBrochure.pdf",
                "Full load runtimes": "11.5 min",
                "Weight": "70 lbs",
                "VA": "700",
                "Dimensions": "8.125\" W x 17.5\" D x 17.5\" H",
                "Half load runtimes": "30 min",
                "WATTS": "500",
                "BTU's/Hour": "256"
            }
        },
        {
            "category": "memory164",
            "manufacturer": "Kingston",
            "model": "HyperX FURY",
            "properties": {
                "Detail": "http://media.kingston.com/pdfs/HyperX_FURY_DDR3_US.pdf",
                "Speed": "1866MHz",
                "Storage Temperature": "-55C to 100C",
                "Type": "DDR3",
                "Dimensions": "133.35mm x 32.8mm",
                "Voltage": "1.35V",
                "Capacity": "8GB",
                "Operating Temperature": "0C to 85C"
            }
        },
        {
            "category": "memory164",
            "manufacturer": "Samsung",
            "model": "generic",
            "properties": {
                "Speed": "1333MHz",
                "Type": "DDR3",
                "Voltage": "1.35V",
                "Part Numbers": "M393B1K70CH0-YH9, M393B1K70DH0-YH9",
                "Capacity": "8GB"
            }
        }
    ]
}

=================
 SIM Information
=================

JSON Requirement:
- SimInfo should always contain the full set of SIM information. Edge Manager services replace the old information with the new.
- SimInfo properties are arbitrary key-values. Keys (like "Prop1" below) are strings. Values contains a string representation of 
  the value and the data type of the data. Refer to Device Detail documentation for a complete list of supported data type.
- Timestamp field must be in RFC3399 format (https://www.ietf.org/rfc/rfc3339.txt) and default to the epoch time if not specified.

Example sim info:
{
    "simInfo": [
        {
            "iccid": "8991101200003111111",
            "imei": "490154203237512",
            "attributes": {
                "Prop2": {
                    "value": "2147483647",
                    "dataType": "DATATYPE_INT"
                },
                "Prop1": {
                    "value": "This is a string",
                    "dataType": "DATATYPE_STRING"
                }
            }
        },
        {
            "iccid": "8991101200003123456",
            "imei": "990000862471854"
        },
        {
            "iccid": "8991101200003987654",
            "imei": "356938035643809"
        }
    ]
}

====================
 Generic Properties
====================
JSON Requirement:
- Properties should always contain the full set of properties. Edge Manager services replace the old information with the new.
- Properties are arbitrary key-values. Keys (like "Prop1" below) are strings. Values contains a string representation of the value
  and the data type of the data. Refer to Device Detail documentation for a complete list of supported data type.
- Timestamp field must be in RFC3399 format (https://www.ietf.org/rfc/rfc3339.txt) and default to the epoch time if not specified. See examples below.

Example device info properties:
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

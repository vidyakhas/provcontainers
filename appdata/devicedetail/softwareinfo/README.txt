Place software information JSON file here.

JSON Requirement:
- File is provided when device is first boot, and when software is added or updated.
- File must contain the full set of software installed. Edge Manager services replace the old information with the new list.
- Timestamp field must be in RFC3399 format (https://www.ietf.org/rfc/rfc3339.txt) and default to the epoch time if not specified. See examples below.
- Type field can be UNKNOWN_TYPE (default), APPLICATION_TYPE, SYSTEM_TYPE, CONFIGURATION_TYPE.
- Only one file is expected. If more than one file is found, the first valid file will be used. Extra files will be renamed to <filename>.extra.<timestamp>.
- SoftwareInfo properties are arbitrary key-values. Keys (like "Tech Support (phone)" below) are strings. Values contains a string representation of 
  the value and the data type of the data. Refer to Device Detail documentation for a complete list of supported data type.

Example software info:
{
    "softwareInfo": [
        {
            "name": "SomeCoolApp",
            "vendor": "Huawei Technologies Co.",
            "type": "APPLICATION_TYPE",
            "version": "1.0.0",
            "installTime": "2016-10-28T03:20:23+00:00",
            "status": "inactive",
            "description": "You wanna run this!",
            "attributes": {
                "Tech Support (phone)": {
                    "value": "123-456-7890",
                    "dataType": "DATATYPE_STRING"
                },
                "Tech Support (email)": {
                    "value": "abcde@huawei.com",
                    "dataType": "DATATYPE_STRING"
                },
                "Tech Support (hours)": {
                    "value": "24x7",
                    "dataType": "DATATYPE_STRING"
                }
            }
        },
        {
            "name": "OpenVPN Client",
            "vendor": "OpenVPN Technologies, Inc.",
            "version": "2.3.12",
            "installTime": "2016-10-25T03:54:43.230Z",
            "status": "active",
            "description": "Securing your traffic"
        },
        {
            "name": "Wind River Linux",
            "vendor": "Wind River",
            "type": "SYSTEM_TYPE",
            "version": "7.0.0.18",
            "installTime": "2016-10-24T18:15:30-05:00",
            "status": "active",
            "description": "Blah"
        }
    ]
}

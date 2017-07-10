This folder contains the scripts required to update the yeti directory.  This
assumes that Predix Machine was installed as a systemd service using the
scripts located in the bin/service_installation directory.  This feature is
not available on the Windows platform.

To create the yeti package
1. zip the full yeti folder
	zip -r yeti.zip yeti/
2. upload the package to EdgeManager
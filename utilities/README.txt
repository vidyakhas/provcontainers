***************************************** The Utility Scripts in this folder **********************************************
 
GenerateContainers:
    - a utility for generating Predix Machine containers without having to install the SDK into an Eclipse environment.
    Given the right arguments, GenerateContainers script will internally invoke DockerizeContainer (described below) script 
    and produce a docker image with the generated Predix Machine installed in one step. 
    This tool can also be used for a continuous integration model.

    Requirements: Eclipse and Maven, and Docker if using the Docker option.
        - Download an Eclipse for generation. This should stay in the zip or tar.gz form. 
        i.e. https://eclipse.org/downloads/ and select the "Eclipse IDE for Java Developers" 
        Whatever Eclipse is selected must have the PDE runtime plugins. This would include the JEE version.
        - The appropriate base docker image (only if using the Docker option)
        e.g. registry.gear.ge.com/predixmachine/openjdk-jre-<architecture>-<version>, installed into Docker's cache.
        If you do not already have the image loaded into your local Docker cache already, you can download the appropriate tarball for the image
        from artifactory (e.g. predixmachine-openjdk-jre-x86_64-1.1.0.tar.gz) and load it into Docker using -
        docker load -i predixmachine-openjdk-jre-x86_64-1.1.0.tar.gz

    Run the script with -h for detailed usage instructions.
        Unix/Linux:
           sh GenerateContainers.sh -h
        Windows
           GenerateContainers.bat -h


DockerizeContainer:
    - a utility for building a docker image with Predix Machine installed.
    This tool can also be used for a continuous integration model.
    
    Examples of valid architectures for the purpose of these instructions are - x86_64 and armhf.
    Requirements:
        - a Predix Machine container, such as one produced by the GenerateContainers script above, or with Eclipse.
        - docker engine installed on the host machine
        - the appropriate base docker image 
          e.g. registry.gear.ge.com/predixmachine/openjdk-jre-<architecture>-<version>, installed into Docker's cache.
          If you do not already have the image loaded into your local Docker cache already, you can download the appropriate tarball for the image
          from artifactory (e.g. predixmachine-openjdk-jre-x86_64-1.1.0.tar.gz) and load it into Docker using -
          docker load -i predixmachine-openjdk-jre-x86_64-1.1.0.tar.gz
        
    Run the script with -h for detailed usage instructions.
        Unix/Linux:
            sh DockerizeContainer.sh -h
        Windows:
            DockerizeContainer.bat -h
            
            
********************************************* The Utility Directories **************************************************

/docker:
	- Directory containing files for use by DockerizeContainer scripts.

/bootstrap:
	- Directory containing instructions on how to get started with Predix Machine on Docker.
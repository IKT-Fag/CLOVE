# Usage - Python

The Python part relies on [netmiko](https://github.com/ktbyers/netmiko).

The Python script is used for automating creation of vlans for each virtual ESXi host. We did this so that the students at our school could have their own subnets. This could be useful if you want to do the same thing, and are using Cisco devices (although the Netmiko module supports more than just Cisco).

## Getting Started

First of all, go into the file `Python\devices.py`. Here you can see how to set up your devices and credentials.

Next, go to `main.py`. This is where it all happens.

What we do is that we gather all of the JSON-files in a specified folder (`jsonFolderImport `). Then, we loop through each host and configure vlans and related config.

If you're not a member of IKT-Fag, this script will most likely be useless to you, as it's pretty much hard-coded for our environment. But, you can at least look at `main.py` as an example on how to use Netmiko.

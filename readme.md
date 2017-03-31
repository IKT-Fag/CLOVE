# CLOVE
*Create Lots Of Virtual ESXi-hosts*

![preview](https://raw.githubusercontent.com/IKT-Fag/CLOVE/master/Docs/Img/preview.png)

## Overview

This collection of scripts are used for mass-creating virtual ESXi hosts. I've based it on [William Lam](https://github.com/lamw)'s [ESXi Nested Appliance](http://www.virtuallyghetto.com/2015/12/deploying-nested-esxi-is-even-easier-now-with-the-esxi-virtual-appliance.html).

I still have to do some refactoring (Like making this into a module), but I've tested all of the script files, and they work just fine.

The most important script file is called `New-ESXiHost.ps1`. This is responsible for installing the host, and doing basic configuration. This repository contains a lot more scripts though for easier automation of other tasks, like domain join, permissions etc.

There is also a Python part, which I used for automating creation of vlans for each virtual ESXi host. I did this so that the students at our school could have their own subnets. This could be useful if you want to do the same thing, and are using Cisco devices (although the Netmiko module supports more than just Cisco).

## How to use

I'm working on this, but if you still want to use these scripts, start with `New-ESXiHost.ps1`. At the bottom of the file you'll find an object, and you can fill in your own info there.

## Requirements

*Must-have*
* PowerShell
* vCenter
* [PowerCLI](https://www.vmware.com/support/developer/PowerCLI/)
* ActiveDirectory module

*If you want to automate Cisco config*
* [Python 2.7.x](https://www.python.org/downloads/)
* [Netmiko](https://github.com/ktbyers/netmiko) (pip install netmiko)

Additionally, `Restart-Services.ps1` requires the Posh-SSH module.

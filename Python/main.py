## This script as-is will not be useful to you, but
## you can use this as a baseline for how to automate 
## your own enviroment.
import os
import sys
import json
from pprint import pprint

## Module imports
from netmiko import ConnectHandler

## Custom files import
from devices import *

## Args
#sys.argv[1] ## First argument, folder to find JSON-files
## Temp for easier testing:
jsonFolderImport = 'C:\\Users\\admin\\Documents\\GitHub\\CLOVE\\Json'

## Loop through all of the json files in jsonFolder and
## add them to a list (vlans) to make the data easy to work with.
def getJson(jsonFolder):
    vlans = []
    for jsonFile in os.listdir(jsonFolder):
        jsonFilePath = jsonFolder + "\\" + jsonFile
        jsonData = open(jsonFilePath, 'r')
        jsonRead = jsonData.read()
        jsonData.close()
        jsonOut = json.loads(jsonRead)
        vlans.append(jsonOut)

    return vlans

## Function to kick off the script
def main():
    vlans = getJson(jsonFolderImport)

    for vlan in vlans:
        print ("Current user: " + str(vlan['User']))
        for device in devicesList:
            ## KobberSwitch
            if device['ip'] == '192.168.0.102':
                print ("Current device: " + device['ip'])
                con = ConnectHandler(**device)

                vlanDat = "vlan " + str(vlan['Vlan'])
                vlanDatName = "name " + vlan['Name'] 
                vlanInt = "interface vlan " + str(vlan['Vlan'])
                intIpConfig = "ip address " + vlan['Subnet'] + " " + vlan['Netmask']
                description = vlan['Description']
              
                commands = [
                    vlanDat,
                    vlanDatName,
                    vlanInt,
                    intIpConfig,
                    description,
                    "no shutdown"
                ]

        

                output = con.send_config_set(commands)
                print ("Configured: " + device['ip'])

                con.send_command('write memory')

                con.disconnect()
            
            ## Core01, Core02
            elif device['ip'] == '192.168.0.100' or device['ip'] == '192.168.0.101':
                print ("Current device: " + device['ip'])
                con = ConnectHandler(**device)
                vlanDat = "vlan " + str(vlan['Vlan'])
                vlanDatName = "name " + vlan['User'] + "-" + vlan['VIServer']
                
                vlanInt = "interface vlan " + str(vlan['Vlan'])

                commands = [
                    vlanDat,
                    vlanDatName,
                    vlanInt,
                    "no shutdown"
                ]
                output = con.send_config_set(commands)
                print ("Configured: " + device['ip'])

                con.send_command('copy running-config startup-config')

                con.disconnect()



main()

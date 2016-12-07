## This is a list of all the devices that needs to get
## new config for the project to work. At the bottom,
## we export a list of all of the arrays.
Rom150 = {
	'device_type': 'cisco_ios',
	'ip': '192.168.0.150',
	'username': 'admin',
	'password': 'Your-device-password-here',
}

KobberSwitch = {
	'device_type': 'cisco_ios',
	'ip': '192.168.0.102',
	'username': 'admin',
	'password': 'Your-device-password-here',
}

Core01 = {
	'device_type': 'cisco_nxos',
	'ip': '192.168.0.100',
	'username': 'admin',
	'password': 'Your-device-password-here',
}

Core02 = {
	'device_type': 'cisco_nxos',
	'ip': '192.168.0.101',
	'username': 'admin',
	'password': 'Your-device-password-here',
}

ASA = {
	'device_type': 'cisco_asa',
	'ip': '192.168.0.1',
	'username': 'admin',
	'password': 'Your-device-password-here',
	'port': '22',
	'secret': ''
}

## Export the list 
devicesList = [Rom150, KobberSwitch, Core01, Core02, ASA]

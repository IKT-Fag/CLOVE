## This is a list of all the devices that needs to get
## new config for the project to work. At the bottom,
## we export a list of all of the arrays.
Rom150 = {
	'device_type': 'cisco_ios',
	'ip': '192.168.0.150',
	'username': 'admin',
	'password': 'network',
}

KobberSwitch = {
	'device_type': 'cisco_ios',
	'ip': '192.168.0.102',
	'username': 'admin',
	'password': 'network',
}

Core01 = {
	'device_type': 'cisco_nxos',
	'ip': '192.168.0.100',
	'username': 'admin',
	'password': 'network',
}

Core02 = {
	'device_type': 'cisco_nxos',
	'ip': '192.168.0.101',
	'username': 'admin',
	'password': 'network',
}

ASA = {
	'device_type': 'cisco_asa',
	'ip': '192.168.0.1',
	'username': 'admin',
	'password': 'firewall',
	'port': '22',
	'secret': ''
}

## Export the list 
devicesList = [Rom150, KobberSwitch, Core01, Core02, ASA]

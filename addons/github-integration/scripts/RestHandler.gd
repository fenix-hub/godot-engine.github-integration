tool
extends Node


var Client : HTTPClient = HTTPClient.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func check_connection() -> bool:
	var connection : int = Client.connect_to_host("www.githubstatus.com")
	assert(connection == OK) # Make sure connection was OK.

	# Wait until resolved and connected.
	print("[GitHub Integration] Connecting to API, please wait...")
	while Client.get_status() == HTTPClient.STATUS_CONNECTING or Client.get_status() == HTTPClient.STATUS_RESOLVING:
		Client.poll()
		OS.delay_msec(500)
	
	if Client.get_status() == HTTPClient.STATUS_CONNECTED:
		print("[GitHub Integration] Connection to API successful")
		return true
	else:
		printerr("[GitHub Integration] Connection to API unsuccessful, exited with error %s, staus: %s" % 
		[Client.get_response_code(), Client.get_status()])
		return false

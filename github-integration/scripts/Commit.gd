tool
extends Control


enum REQUESTS { UPLOAD = 0, UPDATE = 1, END = -1 }
var requesting
var new_repo = HTTPRequest.new()
var repo_body
var file_path

var repo_selected

onready var error = $VBoxContainer/error

func _ready():
	call_deferred("add_child",new_repo)
	new_repo.connect("request_completed",self,"request_completed")
	error.hide()

func request_completed(result, response_code, headers, body ):
	print(result," ",response_code)
	if result == 0:
		match requesting:
			REQUESTS.UPLOAD:
				if response_code == 201:
					hide()
					print(get_parent().plugin_name,"commited and pushed...")
					get_parent().UserPanel.request_repositories(get_parent().UserPanel.REQUESTS.UP_REPOS)
				elif response_code == 422:
					error.text = "Error: "+JSON.parse(body.get_string_from_utf8()).result.errors[0].message
					error.show()
			REQUESTS.UPDATE:
				if response_code == 200:
					pass

func load_body() -> Dictionary:
	file_path = $VBoxContainer/HBoxContainer8/path.text
	var message = $VBoxContainer/HBoxContainer7/message.text
	var file = File.new()
	file.open($VBoxContainer/HBoxContainer/file.text,1)
	var content = Marshalls.utf8_to_base64(file.get_as_text())
	var branch = $VBoxContainer/HBoxContainer2/branch.text
	
	repo_body = {
		  "message":message,
		  "content":content,
		"branch":branch,
		  "committer": {
			"name": get_parent().user_data.login,
			"email": "octocat@github.com"
			},
		}
	
	return repo_body

func _on_Commit_confirmed():
	var bod = JSON.print(load_body())
	error.hide()
	requesting = REQUESTS.UPLOAD
	new_repo.request("https://api.github.com/repos/"+get_parent().user_data.login+"/"+repo_selected+"/contents/"+file_path,["Authorization: Basic "+get_parent().user_logged],false,HTTPClient.METHOD_PUT,bod)

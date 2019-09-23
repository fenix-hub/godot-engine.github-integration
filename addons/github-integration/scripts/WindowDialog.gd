# ----------------------------------------------
#            ~{ GitHub Integration }~
# [Author] Nicolò "fenix" Santilio 
# [github] fenix-hub/godot-engine.github-integration
# [version] 0.2.9
# [date] 09.13.2019





# -----------------------------------------------

tool
extends Control


enum REQUESTS { REPOS = 0, GISTS = 1, END = -1 }
var requesting
var new_repo = HTTPRequest.new()
var repo_body

onready var error = $VBoxContainer/error

func _ready():
	call_deferred("add_child",new_repo)
	new_repo.connect("request_completed",self,"request_completed")
	error.hide()

func request_completed(result, response_code, headers, body ):
	if result == 0:
		match requesting:
			REQUESTS.REPOS:
				if response_code == 201:
					hide()
					print(get_parent().plugin_name,"created new repository...")
					get_parent().UserPanel.request_repositories(get_parent().UserPanel.REQUESTS.UP_REPOS)
					set_default_cursor_shape(CURSOR_ARROW)
					for ch in get_children():
						if !ch is HTTPRequest:
							ch.set_default_cursor_shape(CURSOR_ARROW)
				elif response_code == 422:
					error.text = "Error: "+JSON.parse(body.get_string_from_utf8()).result.errors[0].message
					error.show()
			REQUESTS.GISTS:
				if response_code == 200:
					pass

func load_body() -> Dictionary:
	var priv
	if $VBoxContainer/HBoxContainer3/privacy.get_selected_id() == 0:
		priv = true
	else:
		priv = false
	
	var read
	if $VBoxContainer/HBoxContainer4/readme.pressed:
		read = true
	else:
		read = false
	
	var gitignor = $VBoxContainer/HBoxContainer5/gitignore.get_item_text($VBoxContainer/HBoxContainer5/gitignore.get_selected_id())
	var licens = $VBoxContainer/HBoxContainer6/license.get_item_text($VBoxContainer/HBoxContainer6/license.get_selected_id())
	
	repo_body = {
		  "name": $VBoxContainer/HBoxContainer/nome.text,
		  "description": $VBoxContainer/HBoxContainer2/descrizione.text,
		  "private": priv,
		  "has_issues": true,
		  "has_projects": true,
		  "has_wiki": true,
		  "auto_init": read,
		  "gitignore_template": gitignor,
		  "license_template":  licens
		}
	
	return repo_body

func _on_NewRepo_confirmed():
	set_default_cursor_shape(CURSOR_WAIT)
	for ch in get_children():
		if !ch is HTTPRequest:
			ch.set_default_cursor_shape(CURSOR_WAIT)
	error.hide()
	requesting = REQUESTS.REPOS
	new_repo.request("https://api.github.com/user/repos",UserData.header,false,HTTPClient.METHOD_POST,JSON.print(load_body()))


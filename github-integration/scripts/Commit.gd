tool
extends Control


onready var _message = $VBoxContainer2/HBoxContainer7/message
#onready var _file = $VBoxContainer/HBoxContainer/file
onready var _branch = $VBoxContainer2/HBoxContainer2/branch
onready var file_chooser = $FileDialog
onready var repository = $VBoxContainer2/HBoxContainer/repository
onready var _filters = $VBoxContainer2/HBoxContainer6/filters
onready var _only = $VBoxContainer2/HBoxContainer8/only
onready var Loading = $VBoxContainer2/loading
onready var _start_from = $VBoxContainer2/HBoxContainer9/start_from

enum REQUESTS { UPLOAD = 0, UPDATE = 1, BLOB = 2 , LATEST_COMMIT = 4, BASE_TREE = 5, NEW_COMMIT = 6, PUSH = 7, COMMIT = 9, END = -1 }
var requesting
var new_repo = HTTPRequest.new()
var repo_body
var file_path

var repo_selected
var branches = []
var branches_contents = []
var branch_idx = 0

var files = []
var directories = []

onready var error = $VBoxContainer2/error

signal file_committed()

const DIRECTORY : String = "res://"
var EXCEPTIONS : PoolStringArray = []
var ONLY : PoolStringArray = []
var START_FROM : String = ""

func _ready():
	Loading.hide()
	call_deferred("add_child",new_repo)
	new_repo.connect("request_completed",self,"request_completed")
	error.hide()
	_branch.connect("item_selected",self,"selected_branch")

func request_completed(result, response_code, headers, body ):
#	print(response_code," ",JSON.parse(body.get_string_from_utf8()).result)
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
			REQUESTS.COMMIT:
				if response_code == 201:
					print(get_parent().plugin_name,"file committed!")
					print(get_parent().plugin_name," ")
					emit_signal("file_committed")
				if response_code == 200:
					print(get_parent().plugin_name,"file updated!")
					print(get_parent().plugin_name," ")
					emit_signal("file_committed")
				if response_code == 422:
					print(get_parent().plugin_name,"file already exists, skipping...")
					print(get_parent().plugin_name," ")
					emit_signal("file_committed")


func load_branches(br : Array, s_r : Dictionary, ct : Array) :
	_branch.clear()
	repo_selected = s_r
	branches_contents = ct
	branches = br
	for branch in branches:
		_branch.add_item(branch.name)
	
	repository.text = repo_selected.name+"/"+_branch.get_item_text(branch_idx)

func selected_branch(id : int):
	branch_idx = id
	repository.text = repo_selected.name+"/"+_branch.get_item_text(branch_idx)

# ---------------------------------------------------------

func _on_Button_pressed():
	Loading.show()
	set_default_cursor_shape(CURSOR_WAIT)
	for ch in get_children():
		if !ch is HTTPRequest:
			ch.set_default_cursor_shape(CURSOR_WAIT)
	
	EXCEPTIONS = _filters.text.rsplit(",")
	ONLY = _only.text.rsplit(",")
	START_FROM = _start_from.text
	
	print(get_parent().plugin_name,"getting all files in project...")
	
	list_files_in_directory(DIRECTORY+START_FROM+"/")
	
	request_commit()


# ---------------------------------------------------------


# ---------------- Get all files in project folder

func list_files_in_directory(path):
	directories = []
	
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin(true,false)
	var file = dir.get_next()
	while (file != ""):
		if ! file in EXCEPTIONS:
			if ONLY[0]!=null:
				if dir.current_is_dir():
					if !file.begins_with("."):
							directories.append(dir.get_current_dir()+"/"+file)
				else:
					if file.get_extension()!="import":
						files.append([dir.get_current_dir()+"/"+file,file])
			else:
				if file in ONLY:
					if dir.current_is_dir():
						if !file.begins_with("."):
								directories.append(dir.get_current_dir()+"/"+file)
					else:
						if file.get_extension()!="import":
							files.append([dir.get_current_dir()+"/"+file,file])
			
			
		file = dir.get_next()
	
	dir.list_dir_end()
	
	for directory in directories:
		list_files_in_directory(directory)


func request_commit():
	requesting = REQUESTS.COMMIT
	
	for file in files:
		var content = ""
		var sha = "" # is set to update a file
		
		## this cases are not really necessary, will be used in future versions
		
		if file[0].get_extension()=="png":
			## for images
			var img_src = File.new()
			img_src.open(file[0],File.READ)
			content = Marshalls.raw_to_base64(img_src.get_buffer(img_src.get_len()))
			
		elif file[0].get_extension()=="ttf":
			## for fonts
			var font = File.new()
			font.open(file[0],File.READ)
			content = Marshalls.raw_to_base64(font.get_buffer(font.get_len()))
		else:
			## for readable files
			var f = File.new()
			f.open(file[0],File.READ)
			content = Marshalls.raw_to_base64(f.get_buffer(f.get_len()))
		
		for content in branches_contents:
			if content.path == file[0].lstrip(DIRECTORY+START_FROM+"/"):
				sha = content.sha
		
		print(get_parent().plugin_name,"committing ~> "+file[1])
		
		var bod = {
			"message":_message.get_text(),
			"content":content,
			"branch":_branch.get_item_text(branch_idx),
			"sha":sha,
			"committer": {
				"name": UserData.USER.login,
				"email": UserData.MAIL
			},
		}
		
		new_repo.request("https://api.github.com/repos/"+UserData.USER.login+"/"+repo_selected.name+"/contents/"+file[0].lstrip(DIRECTORY+START_FROM+"/"),UserData.header,false,HTTPClient.METHOD_PUT,JSON.print(bod))
		yield(self,"file_committed")
	
	print(get_parent().plugin_name,"committed everything with success!")
	set_default_cursor_shape(CURSOR_ARROW)
	for ch in get_children():
		if !ch is HTTPRequest:
			ch.set_default_cursor_shape(CURSOR_ARROW)
	
	Loading.hide()



func _on_close2_pressed():
	hide()
	get_parent().Repo.show()


func _on_filters_pressed():
	$filters_dialog.popup()

func _process(delta):
	if Loading.visible:
		loading_anim(delta)

func _on_only_pressed():
	$only_dialog.popup()

func _on_start_from_pressed():
	$start_from.popup()

func loading_anim(delta):
	Loading.set_rotation_degrees((Vector2(Loading.get_rotation_degrees(),0).linear_interpolate(Vector2(360,0), 4 * delta)).x)
	if Loading.get_rotation_degrees() > 330:
		Loading.set_rotation_degrees(0)






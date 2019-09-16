# ----------------------------------------------
#            ~{ GitHub Integration }~
# [Author] Nicolò "fenix" Santilio 
# [github] fenix-hub/godot-engine.github-integration
# [version] 0.2.9
# [date] 09.13.2019





# -----------------------------------------------

tool
extends Control


onready var _message = $VBoxContainer2/HBoxContainer7/message
#onready var _file = $VBoxContainer/HBoxContainer/file
onready var _branch = $VBoxContainer2/HBoxContainer2/branch
onready var file_chooser = $FileDialog
onready var repository = $VBoxContainer2/HBoxContainer/repository
onready var _filters = $VBoxContainer2/HBoxContainer6/filters
onready var _only = $VBoxContainer2/HBoxContainer8/only
onready var Loading = $VBoxContainer2/loading2
onready var _start_from = $VBoxContainer2/HBoxContainer9/start_from

enum REQUESTS { UPLOAD = 0, UPDATE = 1, BLOB = 2 , LATEST_COMMIT = 4, BASE_TREE = 5, NEW_TREE = 8, NEW_COMMIT = 6, PUSH = 7, COMMIT = 9, END = -1 }
var requesting
var new_repo = HTTPRequest.new()

var repo_selected
var branches = []
var branches_contents = []
var branch_idx = 0

var files = []
var directories = []

onready var error = $VBoxContainer2/error

var sha_latest_commit 
var sha_base_tree
var sha_new_tree
var sha_new_commit

var list_file_sha = []


const DIRECTORY : String = "res://"
var EXCEPTIONS : PoolStringArray = []
var ONLY : PoolStringArray = []
var START_FROM : String = ""


signal blob_created()

signal latest_commit()
signal base_tree()
signal new_commit()
signal new_tree()
signal file_blobbed()
signal file_committed()
signal pushed()

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
			REQUESTS.LATEST_COMMIT:
				if response_code == 200:
					sha_latest_commit = JSON.parse(body.get_string_from_utf8()).result.object.sha
					print(get_parent().plugin_name,"got last commit")
					emit_signal("latest_commit")
			REQUESTS.BASE_TREE:
				if response_code == 200:
					sha_base_tree = JSON.parse(body.get_string_from_utf8()).result.tree.sha
					print(get_parent().plugin_name,"got base tree")
					emit_signal("base_tree")
			REQUESTS.BLOB:
				if response_code == 201:
					list_file_sha.append(JSON.parse(body.get_string_from_utf8()).result.sha)
					print(get_parent().plugin_name,"blobbed file")
#					OS.delay_msec(1000)
					emit_signal("file_blobbed")
			REQUESTS.NEW_TREE:
				if response_code == 201:
						sha_new_tree = JSON.parse(body.get_string_from_utf8()).result.sha
						print(get_parent().plugin_name,"created new tree of files")
						emit_signal("new_tree")
			REQUESTS.NEW_COMMIT:
				if response_code == 201:
					sha_new_commit = JSON.parse(body.get_string_from_utf8()).result.sha
					print(get_parent().plugin_name,"created new commit")
					emit_signal("new_commit")
			REQUESTS.PUSH:
				if response_code == 200:
					print(get_parent().plugin_name,"pushed and committed with success!")
					set_default_cursor_shape(CURSOR_ARROW)
					for ch in get_children():
						if !ch is HTTPRequest:
							ch.set_default_cursor_shape(CURSOR_ARROW)
					Loading.hide()
					emit_signal("pushed")

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

# |---------------------------------------------------------|

func _on_Button_pressed():
	Loading.show()
	set_default_cursor_shape(CURSOR_WAIT)
	for ch in get_children():
		if !ch is HTTPRequest:
			ch.set_default_cursor_shape(CURSOR_WAIT)
	
	if _filters.text != "":
		EXCEPTIONS = _filters.text.rsplit(",")
	if _only.text != "":
		ONLY = _only.text.rsplit(",")
	if _start_from.text!= "":
		START_FROM = _start_from.text
	
	print(get_parent().plugin_name,"getting all files in project...")
	
	list_files_in_directory(DIRECTORY+START_FROM+"/")
	
	request_sha_latest_commit()

# |---------------------------------------------------------|


# ---------------- Get all files in project folder

func list_files_in_directory(path):
	directories = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin(true,false)
	var file = dir.get_next()
	while (file != ""):
		print("FILE ",file)
		print("CURRENT DIR ",dir.get_current_dir())
		if ! file in EXCEPTIONS:
			if ONLY.size()<1:
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

# -------------------------------------------------@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

func request_sha_latest_commit():
	requesting = REQUESTS.LATEST_COMMIT
	new_repo.request("https://api.github.com/repos/"+UserData.USER.login+"/"+repo_selected.name+"/git/refs/heads/"+_branch.get_item_text(branch_idx),UserData.header,false,HTTPClient.METHOD_GET,"")
	yield(self,"latest_commit")
	request_base_tree()

func request_base_tree():
	requesting = REQUESTS.BASE_TREE
	new_repo.request("https://api.github.com/repos/"+UserData.USER.login+"/"+repo_selected.name+"/git/commits/"+sha_latest_commit,UserData.header,false,HTTPClient.METHOD_GET,"")
	yield(self,"base_tree")
	request_blobs()

func request_blobs():
	requesting = REQUESTS.BLOB
	list_file_sha.clear()
	
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
		
#		for content in branches_contents:
#			if content.path == file[0].lstrip(DIRECTORY+START_FROM+"/"):
#				sha = content.sha
		
		print(get_parent().plugin_name,"blobbing ~> "+file[1])
		
		var bod = {
			"content":content,
			"encoding":"base64",
		}
		
		new_repo.request("https://api.github.com/repos/"+UserData.USER.login+"/"+repo_selected.name+"/git/blobs",UserData.header,false,HTTPClient.METHOD_POST,JSON.print(bod))
		yield(self,"file_blobbed")
	
	print(get_parent().plugin_name,"blobbed each file with success, start committing...")
	request_commit_tree()

func request_commit_tree():
	requesting = REQUESTS.NEW_TREE
	var tree = []
	for i in range(0,files.size()):
		tree.append({
			"path":files[i][0].right((DIRECTORY+START_FROM+"/").length()),
			"mode":"100644",
			"type":"blob",
			"sha":list_file_sha[i],
			})
	
	var bod = {
		"base_tree": sha_base_tree,
		"tree":tree
		}
	
	new_repo.request("https://api.github.com/repos/"+UserData.USER.login+"/"+repo_selected.name+"/git/trees",UserData.header,false,HTTPClient.METHOD_POST,JSON.print(bod))
	yield(self,"new_tree")
	request_new_commit()

func request_new_commit():
	requesting = REQUESTS.NEW_COMMIT
	var message = _message.text
	var bod = {
		"parents": [sha_latest_commit],
		"tree": sha_new_tree,
		"message": message
		}

	new_repo.request("https://api.github.com/repos/"+UserData.USER.login+"/"+repo_selected.name+"/git/commits",UserData.header,false,HTTPClient.METHOD_POST,JSON.print(bod))
	yield(self,"new_commit")
	request_push_commit()

func request_push_commit():
	requesting = REQUESTS.PUSH
	var bod = {
		"sha": sha_new_commit
		}
	new_repo.request("https://api.github.com/repos/"+UserData.USER.login+"/"+repo_selected.name+"/git/refs/heads/"+_branch.get_item_text(branch_idx),UserData.header,false,HTTPClient.METHOD_POST,JSON.print(bod))
	yield(self,"pushed")
	
	empty_fileds()

# --------------------------------------@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@





func _on_filters_pressed():
	$filters_dialog.popup()


func _on_only_pressed():
	$only_dialog.popup()

func _on_start_from_pressed():
	$start_from.popup()

func _on_loading2_visibility_changed():
	var Mat = Loading.get_material()
	if Loading.visible:
		Mat.set_shader_param("speed",5)
	else:
		Mat.set_shader_param("speed",0)


func _on_close2_pressed():
	empty_fileds()

func empty_fileds():
	files.clear()
	directories.clear()
	sha_latest_commit = ""
	sha_base_tree = ""
	sha_new_tree = ""
	sha_new_commit = ""
	list_file_sha.clear()
	EXCEPTIONS.resize(0)
	ONLY.resize(0)
	START_FROM = ""
	
	_filters.text = ""
	_only.text = ""
	_start_from.text = ""
	
	_message.text = ""
	
	hide()
	get_parent().Repo.show()

# ----------------------------------------------
#            ~{ GitHub Integration }~
# [Author] Nicolò "fenix" Santilio 
# [github] fenix-hub/godot-engine.github-integration
# [version] 0.2.9
# [date] 09.13.2019





# -----------------------------------------------

tool
extends Control

onready var name_ = $Panel2/List/name
onready var html_url_ = $Panel2/List/HBoxContainer5/html_url
onready var owner_ = $Panel2/List/HBoxContainer4/owner
onready var description_ = $Panel2/List/description
onready var default_branch_ = $Panel2/List/HBoxContainer6/default_branch
onready var private_ = $Panel2/List/HBoxContainer7/private
onready var contents_ = $Panel2/contents
onready var closeButton = $Panel2/close
onready var branches_ = $Panel2/List/HBoxContainer8/branch2
onready var DeleteRepo = $Panel2/repos_buttons/delete
onready var Commit = $Panel2/repos_buttons/commit
onready var DeleteRes = $Panel2/repos_buttons/delete2

enum REQUESTS { REPOS = 0, GISTS = 1, UP_REPOS = 2, UP_GISTS = 3, DELETE = 4, COMMIT = 5, BRANCHES = 6, CONTENTS = 7, TREES = 8, DELETE_RESOURCE = 9, END = -1 }
var requesting

var html : String
var request = HTTPRequest.new()
var current_repo
var current_branch
var branches = []
var branches_contents = []
var contents = [] # [0] = name ; [1] = sha ; [2] = path
var dirs = []

var commit_sha = ""
var tree_sha = ""

signal get_branches()
signal get_contents()
signal get_branches_contents()
signal loaded_repo()
signal resource_deleted()

func _ready():
	DeleteRes.disabled = true
	DeleteRes.connect("pressed",self,"delete_resource")
	html_url_.connect("pressed",self,"open_html")
	closeButton.connect("pressed",self,"close_tab")
	DeleteRepo.connect("pressed",self,"delete_repo")
	Commit.connect("pressed",self,"commit")
	add_child(request)
	request.connect("request_completed",self,"request_completed")


func open_repo(repo : TreeItem):
	set_default_cursor_shape(CURSOR_ARROW)
	
	contents_.clear()
	branches_.clear()
	branches.clear()
	contents.clear()
	
	var r = repo.get_metadata(0)
	current_repo = r
	name_.text = r.name
	html = r.html_url
	html_url_.text = r.full_name
	owner_.text = r.owner.login
	private_.text = str(r.private)
	if r.description !=null:
		description_.text = (r.description)
	else:
		description_.text = ""
	default_branch_.text = str(r.default_branch)
	
	request_branches(r.name)


func request_branches(rep : String):
	branches_.clear()
	
	requesting = REQUESTS.BRANCHES
	request.request("https://api.github.com/repos/"+UserData.USER.login+"/"+rep+"/branches",UserData.header,false,HTTPClient.METHOD_GET,"")
	yield(self,"get_branches")
	
	requesting = REQUESTS.TREES
	for b in branches:
		request.request("https://api.github.com/repos/"+UserData.USER.login+"/"+rep+"/branches/"+b.name,UserData.header,false,HTTPClient.METHOD_GET,"")
		yield(self,"get_branches_contents")
	
	var i = 0
	for branch in branches_contents:
		branches_.add_item(branch.name)
		branches_.set_item_metadata(i,branch)
		i+=1
	
	current_branch = branches_.get_item_metadata(0)
	
	request_contents(current_repo.name,branches_.get_item_metadata(0))
	yield(self,"get_contents")
	
	build_list()


func request_contents(rep : String, branch):
	contents.clear()
	contents_.clear()
	
	requesting = REQUESTS.CONTENTS
	request.request("https://api.github.com/repos/"+UserData.USER.login+"/"+rep+"/git/trees/"+branch.commit.commit.tree.sha+"?recursive=1",UserData.header,false,HTTPClient.METHOD_GET,"")


func open_html():
	Input.set_default_cursor_shape(CURSOR_BUSY)
	OS.shell_open(html)
	Input.set_default_cursor_shape(CURSOR_ARROW)

func close_tab():
	contents.clear()
	contents_.clear()
	branches_.clear()
	branches.clear()
	current_repo = ""
	current_branch = ""
	branches.clear()
	branches_contents.clear()
	contents.clear()
	dirs.clear()
	commit_sha = ""
	tree_sha = ""
	hide()
	get_parent().UserPanel.show()



func delete_repo():
	var confirm = ConfirmationDialog.new()
	confirm.dialog_text = "Do you really want to permanently delete /"+current_repo.name+" ?"
	add_child(confirm)
	confirm.rect_position = OS.get_screen_size()/2 - confirm.rect_size/2
	confirm.popup()
	confirm.connect("confirmed",self,"request_delete",[current_repo.name])

func request_delete(repo : String):
	set_default_cursor_shape(CURSOR_WAIT)
	for ch in get_children():
		if !ch is HTTPRequest:
			ch.set_default_cursor_shape(CURSOR_WAIT)
	requesting = REQUESTS.DELETE
	request.request("https://api.github.com/repos/"+UserData.USER.login+"/"+repo,UserData.header,false,HTTPClient.METHOD_DELETE,"")

func request_delete_resource(path : String):
	set_default_cursor_shape(CURSOR_WAIT)
	for ch in get_children():
		if !ch is HTTPRequest:
			ch.set_default_cursor_shape(CURSOR_WAIT)
	requesting = REQUESTS.DELETE_RESOURCE
	
	var body = {
		"message":"",
		"sha": contents_.get_selected().get_metadata(0).sha,
		"branch":current_branch.name
		}
	
	request.request("https://api.github.com/repos/"+UserData.USER.login+"/"+current_repo.name+"/contents/"+path,UserData.header,false,HTTPClient.METHOD_DELETE,JSON.print(body))

func commit():
	hide()
	get_parent().CommitRepo.show()
	get_parent().CommitRepo.load_branches(branches,current_repo,contents)

func request_completed(result, response_code, headers, body ):
	if result == 0:
		match requesting:
			REQUESTS.DELETE:
				if response_code == 204:
					print(get_parent().plugin_name,"deleted repository...")
					OS.delay_msec(1500)
					get_parent().UserPanel.request_repositories(REQUESTS.UP_REPOS)
					close_tab()
					set_default_cursor_shape(CURSOR_ARROW)
					for ch in get_children():
						if !ch is HTTPRequest:
							ch.set_default_cursor_shape(CURSOR_ARROW)
			REQUESTS.BRANCHES:
				if response_code == 200:
					branches = JSON.parse(body.get_string_from_utf8()).result
					emit_signal("get_branches")
			REQUESTS.CONTENTS:
				if response_code == 200:
					contents = JSON.parse(body.get_string_from_utf8()).result.tree
					emit_signal("get_contents")
			REQUESTS.TREES:
				if response_code == 200:
					branches_contents.append(JSON.parse(body.get_string_from_utf8()).result)
					emit_signal("get_branches_contents")
			REQUESTS.DELETE_RESOURCE:
				if response_code == 200:
					print(get_parent().plugin_name,"deleted selected resource")
					contents.erase(contents_.get_selected().get_metadata(0))
					emit_signal("resource_deleted")
				elif response_code == 422:
					print(get_parent().plugin_name,"can't delete a folder!")
					emit_signal("resource_deleted")

func build_list():
	contents_.clear()
	
	for content in contents:
		var ct = contents_.create_item()
		ct.set_text(0,content.path)
		ct.set_metadata(0,content)
	
	emit_signal("loaded_repo")
	show()

func _on_branch2_item_selected(ID):
	current_branch = branches_.get_item_metadata(ID)
	request_contents(current_repo.name,current_branch)
	yield(self,"get_contents")
	build_list()

func delete_resource():
	request_delete_resource(contents_.get_selected().get_metadata(0).path)
	yield(self,"resource_deleted")
	
	
	build_list()
	DeleteRes.disabled = true

func _on_contents_item_activated():
	DeleteRes.disabled = false

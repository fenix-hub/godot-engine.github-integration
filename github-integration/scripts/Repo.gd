tool
extends Control

onready var name_ = $Panel2/List/name
onready var html_url_ = $Panel2/List/HBoxContainer5/html_url
onready var owner_ = $Panel2/List/HBoxContainer4/owner
onready var description_ = $Panel2/List/HBoxContainer2/description
onready var default_branch_ = $Panel2/List/HBoxContainer6/default_branch
onready var private_ = $Panel2/List/HBoxContainer7/private

onready var closeButton = $Panel2/HBoxContainer8/close

onready var DeleteRepo = $Panel2/repos_buttons/delete
onready var Commit = $Panel2/repos_buttons/commit

enum REQUESTS { REPOS = 0, GISTS = 1, UP_REPOS = 2, UP_GISTS = 3, DELETE = 4, COMMIT = 5, END = -1 }
var requesting

var html : String
var request = HTTPRequest.new()
var current_repo

func _ready():
	html_url_.connect("pressed",self,"open_html")
	closeButton.connect("pressed",self,"close_tab")
	DeleteRepo.connect("pressed",self,"delete_repo")
	Commit.connect("pressed",self,"commit")
	add_child(request)
	request.connect("request_completed",self,"request_completed")

func open_repo(repo : TreeItem):
	var r = repo.get_metadata(0)
	current_repo = r.name
	name_.text = r.name
	html = r.html_url
	html_url_.text = r.full_name
	owner_.text = r.owner.login
	private_.text = str(r.private)
	if r.description !=null:
		description_.text = (r.description)
	else:
		description_.text = ""
	default_branch_.text = r.default_branch
	show()

func open_html():
	OS.shell_open(html)

func close_tab():
	hide()
	get_parent().UserPanel.show()

func delete_repo():
	requesting = REQUESTS.DELETE
	var confirm = ConfirmationDialog.new()
	confirm.dialog_text = "Do you really want to permanently delete /"+current_repo+" ?"
	add_child(confirm)
	confirm.rect_position = OS.get_screen_size()/2 - confirm.rect_size/2
	confirm.popup()
	confirm.connect("confirmed",self,"request_delete",[current_repo])

func request_delete(repo : String):
	request.request("https://api.github.com/repos/"+get_parent().user_data.login+"/"+repo,get_parent().UserPanel.header_auth,false,HTTPClient.METHOD_DELETE,"")


func commit():
	requesting = REQUESTS.COMMIT
	get_parent().CommitRepo.popup()
	get_parent().CommitRepo.repo_selected=current_repo
#		confirm.connect("confirmed",self,"request_delete",[repo,selected])
#	else:
#		print(get_parent().plugin_name,"select a repository first!")

func request_completed(result, response_code, headers, body ):
	if result == 0:
		match requesting:
			REQUESTS.DELETE:
				if response_code == 204:
					print(get_parent().plugin_name,"deleted repository...")
					OS.delay_msec(1500)
					get_parent().UserPanel.request_repositories(REQUESTS.UP_REPOS)
					close_tab()
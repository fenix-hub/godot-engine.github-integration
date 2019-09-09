tool
extends Control

onready var User = $Panel/HBoxContainer/user
onready var Avatar = $Panel/HBoxContainer/avatar
onready var Repos = $Panel/List/HBoxContainer2/repos
onready var Gists = $Panel/List/HBoxContainer3/gists
onready var RepoList = $Panel/List/Repos
onready var GistList = $Panel/List/Gist
onready var NewRepo = $Panel/List/repos_buttons/repo

onready var NewGist = $Panel/List/gist_buttons/gist

var header_auth

var request : HTTPRequest = HTTPRequest.new()
#var request_gists : HTTPRequest = HTTPRequest.new()

enum REQUESTS { REPOS = 0, GISTS = 1, UP_REPOS = 2, UP_GISTS = 3, DELETE = 4, COMMIT = 5, END = -1 }
var requesting
var repositories 
var gists

signal completed_loading()

func _ready():
	call_deferred("add_child",request)
	request.connect("request_completed",self,"request_completed")
#	call_deferred("add_child",request_gists)
#	request_gists.connect("request_completed",self,"request_completed")
	NewRepo.connect("pressed",self,"new_repo")
	NewGist.connect("pressed",self,"new_gist")
	RepoList.connect("item_activated",self,"repo_selected")


func load_panel(user : Dictionary, avatar : String) -> void:
	header_auth = ["Authorization: Basic "+get_parent().user_logged]
	Avatar.texture = load(avatar)
	User.text = user.login
	Repos.text = str(user.public_repos)
	Gists.text = str(user.public_gists)
	
	request_repositories(REQUESTS.REPOS)

func request_completed(result, response_code, headers, body ):
	if result == 0:
		match requesting:
			REQUESTS.REPOS:
				if response_code == 200:
					
					repositories = JSON.parse(body.get_string_from_utf8()).result
					load_repositories(repositories)
					print(get_parent().plugin_name,"loaded all repositories...")
					#requesting = REQUESTS.END
			REQUESTS.GISTS:
				if response_code == 200:
					
					gists = JSON.parse(body.get_string_from_utf8()).result
					load_gists(gists)
					print(get_parent().plugin_name,"loaded all gists...")
				#	requesting = REQUESTS.END
					emit_signal("completed_loading")
					show()
			REQUESTS.UP_REPOS:
				if response_code == 200:
					repositories.clear()
					repositories = JSON.parse(body.get_string_from_utf8()).result
					load_repositories(repositories)
					print(get_parent().plugin_name,"updated all repositories...")
			REQUESTS.UP_GISTS:
				if response_code == 200:
					gists.clear()
					gists = JSON.parse(body.get_string_from_utf8()).result
					load_gists(gists)
					print(get_parent().plugin_name,"updated all gists...")
			REQUESTS.DELETE:
				if response_code == 204:
					print(get_parent().plugin_name,"deleted repository...")
					OS.delay_msec(1500)
					request_repositories(REQUESTS.UP_REPOS)


func load_gists(gists : Array) -> void:
	GistList.clear()
	var root = GistList.create_item()
	root.set_text(0,get_parent().user_data.login+"/")
	
	for gis in gists:
		var g = GistList.create_item(root)
		
		if gis.public:
			pass
		else:
			g.set_icon(0,load("res://addons/github-integration/resources//proxy.png"))
		
		g.set_text(0,gis.files.values()[0].filename)
		Gists.text = str(gists.size())
		

func load_repositories(rep : Array) -> void:
	RepoList.clear()
	
	var root = RepoList.create_item()
	root.set_text(0,get_parent().user_data.login+"/")
	
	
	for r in rep:
		var repo = RepoList.create_item(root)
		if r.private:
			repo.set_icon(0,load("res://addons/github-integration/resources//proxy.png"))
		else:
			pass
		repo.set_text(0,str(r.name))
		repo.set_metadata(0,r)
		
	
	Repos.text = str(repositories.size())
	
	if requesting == REQUESTS.REPOS:
		request_gists(REQUESTS.GISTS)


func request_gists(req : int):
	requesting = req
	request.request("https://api.github.com/gists",header_auth,false,HTTPClient.METHOD_GET,"")

func request_repositories(req : int):
	requesting = req
	request.request("https://api.github.com/user/repos",header_auth,false,HTTPClient.METHOD_GET,"")

func new_repo():
	get_parent().NewRepo.popup()
	#request.request()

func repo_selected():
	var repo = RepoList.get_selected()
	get_parent().Repo.open_repo(repo)
	hide()

func new_gist():
	pass
	#request.request()
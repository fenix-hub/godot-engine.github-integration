tool
extends Control

onready var User = $Panel/HBoxContainer/user
onready var Avatar : TextureRect = $Panel/HBoxContainer/avatar
onready var Repos = $Panel/List/HBoxContainer2/repos
onready var Gists = $Panel/List/HBoxContainer3/gists
onready var RepoList = $Panel/List/Repos
onready var GistList = $Panel/List/Gist
onready var NewRepo = $Panel/List/repos_buttons/repo



onready var NewGist = $Panel/List/gist_buttons/gist

onready var GistDialog = $NewGist

var request : HTTPRequest = HTTPRequest.new()

enum REQUESTS { REPOS = 0, GISTS = 1,  UP_REPOS = 2, UP_GISTS = 3, DELETE = 4, COMMIT = 5, BRANCHES = 6, END = -1 }
var requesting
var repositories 
var gists
var branches

signal new_branch()
signal completed_loading()

func _ready():
	load_icons()
	call_deferred("add_child",request)
	request.connect("request_completed",self,"request_completed")
#	call_deferred("add_child",request_gists)
#	request_gists.connect("request_completed",self,"request_completed")
	NewRepo.connect("pressed",self,"new_repo")
	NewGist.connect("pressed",self,"new_gist")
	RepoList.connect("item_activated",self,"repo_selected")
	GistList.connect("item_activated",self,"gist_selected")

func load_panel() -> void:
	Avatar.texture = UserData.AVATAR
	User.text = UserData.USER.login
	Repos.text = str(UserData.USER.public_repos)
	Gists.text = str(UserData.USER.public_gists)
	
	request_repositories(REQUESTS.REPOS)

func load_icons():
	$Panel/List/HBoxContainer3/gists_icon.texture = IconLoaderGithub.load_icon_from_name("gists")
	$Panel/List/HBoxContainer2/repos_icon.texture = IconLoaderGithub.load_icon_from_name("repos")

func request_completed(result, response_code, headers, body ):
	if result == 0:
		match requesting:
			REQUESTS.REPOS:
				if response_code == 200:
					repositories = JSON.parse(body.get_string_from_utf8()).result
					load_repositories(repositories)
					get_parent().print_debug_message("loaded all repositories...")
					#requesting = REQUESTS.END
			REQUESTS.GISTS:
				if response_code == 200:
					gists = JSON.parse(body.get_string_from_utf8()).result
					load_gists(gists)
					get_parent().print_debug_message("loaded all gists...")
					emit_signal("completed_loading")
					show()
			REQUESTS.BRANCHES:
				if response_code == 200:
					branches = JSON.parse(body.get_string_from_utf8()).result
					emit_signal("new_branch")
			REQUESTS.UP_REPOS:
				if response_code == 200:
					repositories.clear()
					repositories = JSON.parse(body.get_string_from_utf8()).result
					load_repositories(repositories)
					get_parent().print_debug_message("updated all repositories...")
			REQUESTS.UP_GISTS:
				if response_code == 200:
					gists.clear()
					gists = JSON.parse(body.get_string_from_utf8()).result
					load_gists(gists)
					get_parent().print_debug_message("updated all gists...")
			REQUESTS.DELETE:
				if response_code == 204:
					get_parent().print_debug_message("deleted repository...")
					OS.delay_msec(1500)
					request_repositories(REQUESTS.UP_REPOS)


func load_gists(gists : Array) -> void:
	GistList.clear()
	var root = GistList.create_item()
	root.set_text(0,UserData.USER.login+"/")
	
	for gis in gists:
		var g = GistList.create_item(root)
		
		if gis.public:
			g.set_icon(0,IconLoaderGithub.load_icon_from_name("gists-back"))
		else:
			g.set_icon(0,IconLoaderGithub.load_icon_from_name("lock"))
		
		g.set_text(0,gis.files.values()[0].filename)
		g.set_metadata(0,gis)
		Gists.text = str(gists.size())
		
		g.set_icon(1,IconLoaderGithub.load_icon_from_name("gists"))
		g.set_text(1,"Files: "+str(gis.files.size()))

func load_repositories(rep : Array) -> void:
	RepoList.clear()
	
	var root = RepoList.create_item()
	root.set_text(0,UserData.USER.login+"/")
	
	
	for r in rep:
		
		var repo = RepoList.create_item(root)
		if r.private:
			repo.set_icon(0,IconLoaderGithub.load_icon_from_name("lock"))
		else:
			if r.fork:
				repo.set_icon(0,IconLoaderGithub.load_icon_from_name("forks"))
			else:
				repo.set_icon(0,IconLoaderGithub.load_icon_from_name("repos-back"))
		repo.set_text(0,str(r.name))
		
		repo.set_icon(1,IconLoaderGithub.load_icon_from_name("stars"))
		repo.set_text(2,"Forked "+str(r.stargazers_count))
		repo.set_icon(2,IconLoaderGithub.load_icon_from_name("forks"))
		repo.set_text(1,"Stars "+str(r.forks_count))
		
		repo.set_metadata(0,r)
		
	Repos.text = str(repositories.size())
	
	if requesting == REQUESTS.REPOS:
		request_gists(REQUESTS.GISTS)

func request_branches(req : int, rep : Dictionary):
	requesting = req
	request.request("https://api.github.com/repos/"+UserData.USER.login+"/"+rep.name+"/branches",UserData.header,false,HTTPClient.METHOD_GET,"")

func request_gists(req : int):
	requesting = req
	request.request("https://api.github.com/gists",UserData.header,false,HTTPClient.METHOD_GET,"")

func request_repositories(req : int):
	requesting = req
	request.request("https://api.github.com/user/repos?per_page=100",UserData.header,false,HTTPClient.METHOD_GET,"")

func new_repo():
	get_parent().NewRepo.popup()
	
	#request.request()

func repo_selected():
	get_parent().print_debug_message("opening selected repository...")
	get_parent().loading(true)
	
	var repo = RepoList.get_selected()
	get_parent().Repo.open_repo(repo)
	yield(get_parent().Repo,"loaded_repo")
	hide()
	
	get_parent().loading(false)

func gist_selected():
	get_parent().print_debug_message("opening selected gist...")
	get_parent().loading(true)
	
	var gist = GistList.get_selected()
	get_parent().Gist.request_gist(gist.get_metadata(0).id)
	yield(get_parent().Gist,"loaded_gist")
	hide()
	
	get_parent().loading(false)

func new_gist():
	GistDialog.popup()


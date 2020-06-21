tool
extends Control

onready var RepositoryItem = preload("res://addons/github-integration/scenes/RepositoryItem.tscn")

onready var User = $Panel/HBoxContainer/user
onready var Avatar : TextureRect = $Panel/HBoxContainer/avatar
onready var Repos = $Panel/List/HBoxContainer2/repos
onready var Gists = $Panel/List/HBoxContainer3/gists
onready var RepoList = $Panel/List/ScrollContainer/Repos
onready var GistList = $Panel/List/Gist
onready var NewRepo = $Panel/List/repos_buttons/repo
onready var ReloadBtn = $ReloadBtn

onready var SearchRepo = $Panel/List/HBoxContainer2/search_repo

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
#	RepoList.connect("item_activated",self,"repo_selected")
    GistList.connect("item_activated",self,"gist_selected")
    
    ReloadBtn.connect("pressed",self,"_reload")
    SearchRepo.connect("text_changed",self,"_on_search_repo")

func load_panel() -> void:
    Avatar.texture = UserData.AVATAR
    User.text = UserData.USER.login
    Repos.text = str(UserData.USER.public_repos)
    Gists.text = str(UserData.USER.public_gists)
    
    request_repositories(REQUESTS.REPOS)

func load_icons():
    $Panel/List/HBoxContainer3/gists_icon.texture = IconLoaderGithub.load_icon_from_name("gists")
    $Panel/List/HBoxContainer2/repos_icon.texture = IconLoaderGithub.load_icon_from_name("repos")
    ReloadBtn.icon = IconLoaderGithub.load_icon_from_name("reload")

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

var repository_list : Array = []

func load_repositories(rep : Array) -> void:
    repository_list.clear()
    
    for repository in rep:
        var repo_item = RepositoryItem.instance()
        RepoList.add_child(repo_item)
        repo_item.set_repository(repository)
        repo_item.connect("repo_selected",self,"repo_selected")
        repo_item.connect("repo_clicked",self,"repo_clicked")
        repository_list.append(repo_item)
    
    Repos.text = str(repositories.size())
    
    if requesting == REQUESTS.REPOS:
        request_gists(REQUESTS.GISTS)

func repo_clicked(clicked_repo : Dictionary):
    for repository in repository_list:
        if repository._repository!=clicked_repo:
            repository.deselect()

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

func repo_selected(repository : Dictionary):
    get_parent().print_debug_message("opening selected repository...")
    get_parent().loading(true)
    
#	var repo = RepoList.get_selected()
    get_parent().Repo.open_repo(repository)
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

func _reload():
    get_parent().loading(true)
    get_parent().print_debug_message("Reloading, please wait...")
    request_repositories(REQUESTS.REPOS)
    yield(self,"completed_loading")
    get_parent().loading(false)

func _on_search_repo(repo_name : String):
    for repository in repository_list:
        if repo_name!="":
            if repo_name.to_lower() in repository._name.to_lower():
                repository.show()
            else:
                repository.hide() 
        else:
            repository.show()

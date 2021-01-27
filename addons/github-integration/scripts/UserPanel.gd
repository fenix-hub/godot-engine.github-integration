tool
extends Control

onready var _repository_item = preload("res://addons/github-integration/scenes/RepositoryItem.tscn")
onready var _gist_item = preload("res://addons/github-integration/scenes/GistItem.tscn")

onready var Avatar : TextureRect = $Panel/HBoxContainer/avatar
onready var GistIcon : TextureRect = $Panel/List/GistHeader/gists_icon
onready var RepoIcon : TextureRect = $Panel/List/RepositoryHeader/repos_icon

onready var User : Label  = $Panel/HBoxContainer/user
onready var Repos : Label = $Panel/List/RepositoryHeader/repos
onready var Gists : Label = $Panel/List/GistHeader/gists
onready var RepoList : VBoxContainer = $Panel/List/RepositoryList/Repos
onready var GistList : VBoxContainer = $Panel/List/GistList/Gists
onready var NewRepo : Button = $Panel/List/repos_buttons/repo
onready var NewGist : Button = $Panel/List/gist_buttons/gist
onready var ReloadBtn : Button = $ReloadBtn

onready var SearchRepo : LineEdit = $Panel/List/RepositoryHeader/search_repo
onready var SearchGist : LineEdit = $Panel/List/GistHeader/search_gist

onready var GistDialog : WindowDialog = $NewGist
onready var RepoDialog : ConfirmationDialog = $NewRepo

signal new_branch()
signal completed_loading()
signal loaded_repositories()
signal loaded_gists()

var request : HTTPRequest = HTTPRequest.new()
enum REQUESTS { REPOS = 0, GISTS = 1,  UP_REPOS = 2, UP_GISTS = 3, DELETE = 4, COMMIT = 5, BRANCHES = 6, END = -1 }
var requesting : int
#var repositories : Array = []
var gists : Array = []
var branches : Array = []
var repository_list : Array = []
var gist_list : Array = []

func _ready():
    load_icons()
    call_deferred("add_child",request)
    _connect_signals()

func _connect_signals() -> void:
    NewRepo.connect("pressed",self,"new_repo")
    NewGist.connect("pressed",self,"new_gist")
    ReloadBtn.connect("pressed",self,"_reload")
    SearchRepo.connect("text_changed",self,"_on_search_repo")
    SearchGist.connect("text_changed",self,"_on_search_gist")
    
    RestHandler.connect("request_failed", self, "_on_request_failed")
    RestHandler.connect("user_repositories_requested",self,"_on_user_repositories_requested")
    RestHandler.connect("user_gists_requested", self, "_on_user_gists_requested")
    $Panel/List/gist_buttons/reload.connect("pressed", self, "request_gists")
    $Panel/List/repos_buttons/reload.connect("pressed", self, "request_repositories")

func set_darkmode(darkmode : bool):
    if darkmode:
        $BG.color = "#24292e"
        set_theme(load("res://addons/github-integration/resources/themes/GitHubTheme-Dark.tres"))
        $Panel/List/RepositoryList.set("custom_styles/bg", load("res://addons/github-integration/resources/styles/List-black.tres"))
        $Panel/List/GistList.set("custom_styles/bg", load("res://addons/github-integration/resources/styles/List-black.tres"))
    else:
        $BG.color = "#f6f8fa"
        set_theme(load("res://addons/github-integration/resources/themes/GitHubTheme.tres"))
        $Panel/List/RepositoryList.set("custom_styles/bg", load("res://addons/github-integration/resources/styles/List-white.tres"))
        $Panel/List/GistList.set("custom_styles/bg", load("res://addons/github-integration/resources/styles/List-white.tres"))

func load_icons():
    GistIcon.texture = IconLoaderGithub.load_icon_from_name("gists")
    RepoIcon.texture = IconLoaderGithub.load_icon_from_name("repos")
    ReloadBtn.icon = IconLoaderGithub.load_icon_from_name("reload-gray")
    NewRepo.icon = IconLoaderGithub.load_icon_from_name("repos")
    NewGist.icon = IconLoaderGithub.load_icon_from_name("gists")

# ----- signals 
func _on_request_failed(request_code : int, error_body : Dictionary) -> void:
    match request_code:
        RestHandler.REQUESTS.USER_REPOSITORIES:
            get_parent().print_debug_message("ERROR "+str(request_code)+" : "+error_body.message)

func _on_user_repositories_requested(body : Dictionary) -> void:
    var repositories : Array = body.user.repositories.nodes 
    if PluginSettings.owner_affiliations.has("ORGANIZATION_MEMBER"):
        for organization in body.user.organizations.nodes:
            repositories += organization.repositories.nodes
    load_repositories(repositories)

func _on_user_gists_requested(body : Dictionary) -> void:
    var gists : Array = body.user.gists.nodes
    load_gists(gists)

# ...................... after requests logic .........................
func load_panel() -> void:
#	Repos.text = str(UserData.USER.public_repos)
#	Gists.text = str(UserData.USER.public_gists)
    request_repositories()
    yield(RestHandler, "user_repositories_requested")
    request_gists()
    yield(RestHandler, "user_gists_requested")
    emit_signal("completed_loading")
    show()

func request_gists():
    get_parent().loading(true)
    get_parent().print_debug_message("loading gists, please wait...")
    RestHandler.request_user_gists()

func request_repositories():
    get_parent().loading(true)
    get_parent().print_debug_message("loading repositories, please wait...\n(if the total of your repositories is >100 this will take a little longer.)")
    RestHandler.request_user_repositories()

func load_repositories(repositories : Array) -> void:
    clear_repo_list()
    
    for repository in repositories:
        var is_listed : bool = false
        for repository_item in repository_list:
            if repository_item.name == repository.name:
                is_listed = true
                continue
        if is_listed:
            continue
        var repo_item = _repository_item.instance()
        RepoList.add_child(repo_item)
        repo_item.set_repository(repository)
        repo_item.connect("repo_selected",self,"repo_selected")
        repo_item.connect("repo_clicked",self,"repo_clicked")
        repository_list.append(repo_item)
    
    Repos.text = str(repositories.size())
    get_parent().print_debug_message("loaded all repositories...")
    emit_signal("loaded_repositories")
    get_parent().loading(false)

func load_gists(gists : Array) -> void:
    clear_gist_list()
    
    for gist in gists:
        var gist_item = _gist_item.instance()
        GistList.add_child(gist_item)
        gist_item.set_gist(gist)
        gist_item.connect("gist_selected",self,"gist_selected")
        gist_item.connect("gist_clicked",self,"gist_clicked")
        gist_list.append(gist_item)
    
    Gists.text = str(gists.size())
    get_parent().print_debug_message("loaded all gists...")
    emit_signal("loaded_gists")
    get_parent().loading(false)

func request_completed(result : int, response_code : int, headers : PoolStringArray, body : PoolByteArray ):
    if result == 0:
        match requesting:
            REQUESTS.BRANCHES:
                if response_code == 200:
                    branches = JSON.parse(body.get_string_from_utf8()).result
                    emit_signal("new_branch")
            REQUESTS.DELETE:
                if response_code == 204:
                    get_parent().print_debug_message("deleted repository...")
                    OS.delay_msec(1500)

func request_branches(req : int, rep : Dictionary):
    requesting = req
    request.request("https://api.github.com/repos/"+UserData.USER.login+"/"+rep.name+"/branches",UserData.header,false,HTTPClient.METHOD_GET,"")

func new_repo():
    RepoDialog.popup()

# Items clicked ...............................
func repo_clicked(clicked_repo : RepositoryItem):
    for repository in repository_list:
        if repository!=clicked_repo:
            repository.deselect()

func gist_clicked(clicked_gist : GistItem):
    for gist in gist_list:
        if gist!=clicked_gist:
            gist.deselect()

# Items selected ...............................
func repo_selected(repository : RepositoryItem):
    get_parent().print_debug_message("opening selected repository...")
    get_parent().loading(true)
    get_parent().Repo.open_repository(repository)

func gist_selected(gist : GistItem):
    get_parent().print_debug_message("opening selected gist...")
    get_parent().loading(true)
    get_parent().Gist.load_gist(gist)
# ............................................

func new_gist():
    GistDialog.popup()

func _reload():
    _clear()
    get_parent().loading(true)
    get_parent().print_debug_message("Reloading, please wait...")
    RestHandler.request_user_repositories()

func _clear() -> void:
    clear_repo_list()
    clear_gist_list()
    SearchGist.text = ""
    SearchRepo.text = ""

func clear_repo_list():
    for repository in RepoList.get_children():
        repository.free()
    repository_list.clear()

func clear_gist_list():
    for gist in GistList.get_children():
        gist.free()
    gist_list.clear()

# ................................................ search functions
func _on_search_repo(repo_name : String):
    for repository in repository_list:
        if repo_name!="":
            if repo_name.to_lower() in repository._name.to_lower():
                repository.show()
            else:
                repository.hide() 
        else:
            repository.show()

func _on_search_gist(gist_name : String):
    for gist in gist_list:
        if gist_name!="":
            if gist_name.to_lower() in gist._name.to_lower():
                gist.show()
            else:
                gist.hide() 
        else:
            gist.show()

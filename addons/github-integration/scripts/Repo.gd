# ----------------------------------------------
#            ~{ GitHub Integration }~
# [Author] Nicolò "fenix" Santilio
# [github] fenix-hub/godot-engine.github-integration
# [version] 0.2.9
# [date] 09.13.2019





# -----------------------------------------------

tool
extends Control

onready var repo_icon : TextureRect = $Repository/RepoInfos/RepoInfosContainer/repo_infos/repo_icon
onready var private_icon : TextureRect = $Repository/RepoInfos/RepoInfosContainer/repo_infos/private_icon
onready var star_icon : TextureRect = $Repository/RepoInfos/RepoInfosContainer/repo_infos/star_values/star_icon
onready var fork_icon : TextureRect = $Repository/RepoInfos/RepoInfosContainer/repo_infos/fork_values/fork_icon
onready var forked_icon : TextureRect = $Repository/RepoInfos/RepoInfosContainer/repo_infos/forked_icon

onready var extension_option = $extension_choosing/VBoxContainer/extension_option
onready var extension_choosing = $extension_choosing
#onready var watch_value = $Repository/RepoInfos/RepoInfosContainer/repo_infos/watch_values/watch
onready var star_value : Label = $Repository/RepoInfos/RepoInfosContainer/repo_infos/star_values/star
onready var fork_value : Label = $Repository/RepoInfos/RepoInfosContainer/repo_infos/fork_values/fork

onready var owner_lbl : Label = $Repository/RepoInfos/RepoInfosContainer/repo_infos/repo_owner
onready var description_lbl : Label = $Repository/RepositoryInfo/RepositoryDetails/About/Description
onready var default_branch_lbl : Label = $Repository/RepositoryInfo/RepositoryContent/BranchInfo/branch/HBoxContainer6/default_branch
onready var repo_name_link : LinkButton = $Repository/RepoInfos/RepoInfosContainer/repo_infos/repo_name
onready var contents_tree : Tree = $Repository/RepositoryInfo/RepositoryContent/contents
onready var close_btn : TextureButton = $Repository/RepoInfos/RepoInfosContainer/close
onready var branches_opt_btn : OptionButton = $Repository/RepositoryInfo/RepositoryContent/BranchInfo/branch/branch2
onready var delete_repository_btn : Button = $Repository/repos_buttons/HBoxContainer2/delete
onready var commit_btn : Button = $Repository/repos_buttons/HBoxContainer3/commit
onready var delete_resource_btn : Button = $Repository/repos_buttons/HBoxContainer2/delete2

onready var reload_btn :Button = $Repository/repos_buttons/HBoxContainer/reload
onready var new_branch_btn : Button = $Repository/RepositoryInfo/RepositoryContent/BranchInfo/branch/new_branchBtn
onready var new_branch_dialog : AcceptDialog = $NewBranch
onready var pull_btn : Button = $Repository/RepositoryInfo/RepositoryContent/BranchInfo/branch/pull_btn
onready var git_lfs = $Repository/RepositoryInfo/RepositoryContent/BranchInfo/branch/git_lfs

onready var from_branch : OptionButton = $NewBranch/VBoxContainer/HBoxContainer2/from_branch

onready var ExtractionRequest = $extraction_request
onready var ExtractionOverwriting = $extraction_overwriting

onready var SetupDialog = $setup_git_lfs
onready var WhatIsDialog = $whatis_dialog

onready var ExtensionsList = $setup_git_lfs/VBoxContainer/extensions_list

# Collaborators
onready var add_collaborator_btn : Button = $Repository/RepositoryInfo/RepositoryDetails/Collaborators/AddCollaboratorBtn
onready var AddCollaborator : AcceptDialog = $AddCollaborator
onready var CollaboratorName : LineEdit = $AddCollaborator/VBoxContainer/HBoxContainer/name
onready var CollaboratorPermission : OptionButton = $AddCollaborator/VBoxContainer/HBoxContainer2/permission

# Details
onready var collaborators_list : VBoxContainer = $Repository/RepositoryInfo/RepositoryDetails/Collaborators/ListContainer/List
onready var contributors_list : VBoxContainer = $Repository/RepositoryInfo/RepositoryDetails/Contributors/ListContainer/List

var contributor_class : PackedScene = load("res://addons/github-integration/scenes/ContributorClass.tscn")

enum REQUESTS { REPOS = 0, GISTS = 1, UP_REPOS = 2, UP_GISTS = 3, DELETE = 4, COMMIT = 5, BRANCHES = 6, CONTENTS = 7, TREES = 8, DELETE_RESOURCE = 9, END = -1 , FILE_CONTENT = 10 ,NEW_BRANCH = 11 , PULLING = 12, COLLABORATOR = 13 }
var requesting

var current_repo : PanelContainer
var html : String
var current_branch
var branches = []
var branches_contents = []
var contents = [] # [0] = name ; [1] = sha ; [2] = path
var dirs = []
var item_repo : TreeItem

var commit_sha = ""
var tree_sha = ""

var multi_selected : Array = []
var gitignore_file : Dictionary

var zip_filepath : String = ""
var archive_extension : String = ""

signal resource_deleted()

func _ready():
    _connect_signals()
    delete_resource_btn.disabled = true

func _connect_signals() -> void:
    delete_resource_btn.connect("pressed",self,"delete_resource")
    repo_name_link.connect("pressed",self,"open_html")
    close_btn.connect("pressed",self,"close_tab")
    delete_repository_btn.connect("pressed",self,"delete_repo")
    commit_btn.connect("pressed",self,"commit")
    new_branch_btn.connect("pressed",self,"on_newbranch_pressed")
    new_branch_dialog.connect("confirmed",self,"on_newbranch_confirmed")
    pull_btn.connect("pressed",self,"on_pull_pressed")
    git_lfs.connect("pressed",self,"setup_git_lfs")
    add_collaborator_btn.connect("pressed", self, "add_collaborator")
    AddCollaborator.connect("confirmed",self,"invite_collaborator")
    
    RestHandler.connect("user_repository_requested",self, "_on_user_repository_requested")
    RestHandler.connect("request_failed", self, "_on_request_failed")
    RestHandler.connect("branch_contents_requested", self, "_on_branch_contents_requested")
    RestHandler.connect("gitignore_requested", self, "_on_gitignore_requested")
    RestHandler.connect("pull_branch_requested", self, "_on_pull_branch_requested")
    RestHandler.connect("collaborator_requested", self, "_on_collaborator_requested")
    RestHandler.connect("resource_delete_requested", self, "_on_delete_resource_requested")
    RestHandler.connect("repository_delete_requested", self, "_on_repository_deleted")
    RestHandler.connect("new_branch_requested", self, "_on_new_branch_created")

func set_darkmode(darkmode : bool):
    if darkmode:
        $BG.color = "#24292e"
        set_theme(load("res://addons/github-integration/resources/themes/GitHubTheme-Dark.tres"))
        $Repository/RepoInfos.set("custom_styles/panel",load("res://addons/github-integration/resources/styles/Repohead-black.tres"))
        $Repository/RepositoryInfo/RepositoryContent/BranchInfo.set("custom_styles/panel",load("res://addons/github-integration/resources/styles/Branch-black.tres"))
        contents_tree.set("custom_styles/bg", load("res://addons/github-integration/resources/styles/ContentesBG-dark.tres"))   
        contents_tree.set("custom_styles/bg_focus", load("res://addons/github-integration/resources/styles/ContentesBG-dark.tres"))   
    else:
        $BG.color = "#f6f8fa"
        set_theme(load("res://addons/github-integration/resources/themes/GitHubTheme.tres"))
        $Repository/RepoInfos.set("custom_styles/panel",load("res://addons/github-integration/resources/styles/Repohead-white.tres"))
        $Repository/RepositoryInfo/RepositoryContent/BranchInfo.set("custom_styles/panel",load("res://addons/github-integration/resources/styles/Branch-white.tres"))
        contents_tree.set("custom_styles/bg", load("res://addons/github-integration/resources/styles/ContentesBG-white.tres"))
        contents_tree.set("custom_styles/bg_focus", load("res://addons/github-integration/resources/styles/ContentesBG-white.tres"))

func load_icons(r : Dictionary):
    repo_icon.set_texture(IconLoaderGithub.load_icon_from_name("repos"))
    if r.isPrivate:
            private_icon.set_texture(IconLoaderGithub.load_icon_from_name("lock"))
    if r.isFork:
            forked_icon.set_texture(IconLoaderGithub.load_icon_from_name("forks"))
#    watch_icon.set_texture(IconLoaderGithub.load_icon_from_name("watch"))
    star_icon.set_texture(IconLoaderGithub.load_icon_from_name("stars"))
    fork_icon.set_texture(IconLoaderGithub.load_icon_from_name("forks"))
    reload_btn.set_button_icon(IconLoaderGithub.load_icon_from_name("reload-gray"))
    new_branch_btn.set_button_icon(IconLoaderGithub.load_icon_from_name("add-gray"))
    pull_btn.set_button_icon(IconLoaderGithub.load_icon_from_name("download-gray"))
    git_lfs.set_button_icon(IconLoaderGithub.load_icon_from_name("git_lfs-gray"))
    add_collaborator_btn.set_button_icon(IconLoaderGithub.load_icon_from_name("add-gray"))

func open_repository(repository_item : PanelContainer) -> void:
    _clear()
    
    # Load repository's info ....
    current_repo = repository_item
    var repository : Dictionary = repository_item._repository
    html = repository.url
    owner_lbl.text = repository.owner.login
    repo_name_link.text = repository.name
    branches = (repository.refs.nodes as Array).duplicate()
    
    if repository.description !=null:
        description_lbl.text = (repository.description)
    else:
        description_lbl.text = ""
    star_value.set_text(str(repository.stargazerCount))
    fork_value.set_text(str(repository.forkCount))
    
    load_icons(repository)
    
    if repository.collaborators != null : 
        load_collaborators(repository.collaborators.nodes as Array)
        load_contributors(collaborators_login, repository.mentionableUsers.nodes as Array)
    
    if branches.size():
        default_branch_lbl.text = str(repository.defaultBranchRef.name)
        current_branch = branches[0]
        load_branches()
        get_parent().print_debug_message("loading current branch contents, please wait...")
        RestHandler.request_branch_contents(repository.name, repository.owner.login, current_branch)
    else:
        get_parent().print_debug_message("this repository is empty.")
        get_parent().loading(false)
        show()

func _on_user_repository_requested(repository : Dictionary):
    current_repo.set_repository(repository.user.repository if repository.has("user") else repository.organization.repository)
    open_repository(current_repo)

var collaborators_login : Array = []

func load_collaborators(collaborators : Array) -> void:
    collaborators_login = []
    for contributor in collaborators_list.get_children():
        contributor.free()
    
    for contributor in collaborators:
        collaborators_login.append(contributor.login)
        var temp_contributor_class : ContributorClass = contributor_class.instance()
        collaborators_list.add_child(temp_contributor_class)
        temp_contributor_class.load_contributor(contributor.login, contributor.name if contributor.name!=null else "", contributor.avatarUrl)

func load_contributors(collaborators : Array, contributors : Array) -> void:
    for contributor in contributors_list.get_children():
        contributor.free()
    
    for contributor in contributors:
        if contributor.login in collaborators_login:
            continue
        var temp_contributor_class : ContributorClass = contributor_class.instance()
        contributors_list.add_child(temp_contributor_class)
        temp_contributor_class.load_contributor(contributor.login, contributor.name if contributor.name!=null else "", contributor.avatarUrl)

func load_branches() -> void:
    get_parent().print_debug_message("loading branches...")
    for branch_idx in range(branches.size()):
        branches_opt_btn.add_item(branches[branch_idx].name)
        branches_opt_btn.set_item_metadata(branch_idx, branches[branch_idx])
        from_branch.add_item(branches[branch_idx].name)
        from_branch.set_item_metadata(branch_idx, branches[branch_idx])

func _on_branch_contents_requested(branch_contents : Dictionary):
    contents = branch_contents.tree
    build_list()

func _on_gitignore_requested(gitignore : Dictionary):
    gitignore_file = gitignore

func open_html():
    get_parent().loading(true)
    OS.shell_open(html)
    get_parent().loading(false)

func close_tab():
    _clear()
    hide()
    get_parent().UserPanel.show()

func delete_repo():
    var confirm = ConfirmationDialog.new()
    confirm.dialog_text = "Do you really want to permanently delete /"+current_repo._name+" ?"
    add_child(confirm)
    confirm.rect_position = OS.get_screen_size()/2 - confirm.rect_size/2
    confirm.popup()
    confirm.connect("confirmed", self, "delete_repository")
    confirm.get_cancel().connect("pressed", confirm, "free")

func delete_repository():
    get_parent().loading(true)
    RestHandler.request_delete_repository(current_repo._repository.owner.login, current_repo._name)

func _on_repository_deleted():
    get_parent().print_debug_message("deleted repository...")
    OS.delay_msec(1500)
    get_parent().UserPanel.request_repositories()
    close_tab()

func delete_resource():
    if multi_selected.size()>0:
        for item in multi_selected:
            request_delete_resource(item.get_metadata(0).path, item)
            get_parent().print_debug_message("deleting "+item.get_metadata(0).path+"...")
            yield(self,"resource_deleted")
    else:
        request_delete_resource(contents_tree.get_selected().get_metadata(0).path)
        get_parent().print_debug_message("deleting "+contents_tree.get_selected().get_metadata(0).path+"...")
        yield(self,"resource_deleted")
    multi_selected.clear()
    _on_reload_pressed()
    delete_resource_btn.disabled = true

func request_delete_resource(path : String, item : TreeItem = null):
    get_parent().loading(true)
    requesting = REQUESTS.DELETE_RESOURCE
    var body
    if multi_selected.size()>0:
        body = {
                "message":"",
                "sha": multi_selected[multi_selected.find(item)].get_metadata(0).sha,
                "branch":current_branch.name
                }
    else:
        body = {
                "message":"",
                "sha": contents_tree.get_selected().get_metadata(0).sha,
                "branch":current_branch.name
                }
    RestHandler.request_delete_resource(current_repo._repository.owner.login, current_repo._name, path, body)

func _on_delete_resource_requested() -> void:
    get_parent().print_debug_message("deleted selected resource")
    if multi_selected.size()>0:
        contents.remove(0)
    else:
        contents.erase(contents_tree.get_selected().get_metadata(0))
    emit_signal("resource_deleted")

func commit():
    hide()
    get_parent().CommitRepo.show()
    get_parent().CommitRepo.load_branches(branches,current_repo,contents,gitignore_file)

func _on_request_failed(requesting : int, error_body : Dictionary) -> void:
    match requesting:
        RestHandler.REQUESTS.INVITE_COLLABORATOR:
            get_parent().print_debug_message("ERROR: %s" % error_body.errors[0].message, 1)
        RestHandler.REQUESTS.DELETE_RESOURCE:
            get_parent().print_debug_message("ERROR: can't delete a folder!",1)
        RestHandler.REQUESTS.NEW_BRANCH:
            get_parent().print_debug_message("ERROR: %s" % error_body.errors[0].message, 1)
    get_parent().loading(false)

func build_list():
    get_parent().print_debug_message("building branch contents, please wait...")
    contents_tree.clear()
    get_parent().loading(true)
    var root = contents_tree.create_item()
    var directories : Array = []
    for content in contents:
        var content_name = content.path.get_file()
        var content_type = content.type
        if content_type == "blob":
            if content.path.get_file() == ".gitignore":
                RestHandler.request_gitignore(current_repo._repository.owner.login, current_repo._repository.name, current_branch.name)
            else:
                gitignore_file = {}
            var file_dir = null
            for directory in directories:
                if directory.get_metadata(0).path == content.path.get_base_dir():
                    file_dir = directory
                    continue
            var item = contents_tree.create_item(file_dir)
            item.set_text(0,content_name)
            var icon
            var extension = content_name.get_extension()
            if extension == "gd":
                icon = IconLoaderGithub.load_icon_from_name("script-gray")
            elif extension == "tscn":
                icon = IconLoaderGithub.load_icon_from_name("scene-gray")
            elif extension == "png":
                icon = IconLoaderGithub.load_icon_from_name("image-gray")
            elif extension == "tres":
                icon = IconLoaderGithub.load_icon_from_name("resource-gray")
            else:
                icon = IconLoaderGithub.load_icon_from_name("file-gray")
            item.set_icon(0,icon)
            item.set_metadata(0,content)
        elif content_type == "tree":
                var dir_dir = null
                for directory in directories:
                    if directory.get_metadata(0).path == content.path.get_base_dir():
                            dir_dir = directory
                            continue
                var new_dir = contents_tree.create_item(dir_dir)
                new_dir.set_text(0,content_name)
                new_dir.set_icon(0,IconLoaderGithub.load_icon_from_name("dir-gray"))
                new_dir.set_metadata(0,content)
                directories.append(new_dir)
                new_dir.set_collapsed(true)
    get_parent().print_debug_message("contents loaded.")
    get_parent().loading(false)
    show()

func _on_branch2_item_selected(ID : int):
    get_parent().loading(true)
    current_branch = branches_opt_btn.get_item_metadata(ID)
    RestHandler.request_branch_contents(current_repo._name, current_repo._repository.owner.login, current_branch)

func _on_contents_item_activated():
    delete_resource_btn.disabled = false

func _on_contents_item_selected():
    pass

func _on_contents_multi_selected(item, column : int, selected):
    if not multi_selected.has(item):
        multi_selected.append(item)
    else:
        multi_selected.erase(item)
    delete_resource_btn.disabled = false

func on_newbranch_pressed():
    new_branch_dialog.get_node("VBoxContainer/HBoxContainer/name").clear()
    new_branch_dialog.popup()

func on_newbranch_confirmed():
    requesting = REQUESTS.NEW_BRANCH
    if " " in new_branch_dialog.get_node("VBoxContainer/HBoxContainer/name").get_text():
            get_parent().print_debug_message("ERROR: a branch name cannot contain spaces. Please, use '-' or '_' instead.",1)
            return
    var body = {
            "ref": "refs/heads/"+new_branch_dialog.get_node("VBoxContainer/HBoxContainer/name").get_text(),
            "sha": from_branch.get_item_metadata(from_branch.get_selected_id()).target.oid
    }
    RestHandler.request_create_new_branch(current_repo._repository.owner.login, current_repo._name, body)
    get_parent().print_debug_message("creating new branch...")

func _on_new_branch_created() -> void:
    get_parent().print_debug_message("new branch created!")
    _on_reload_pressed()

func on_pull_pressed():
    extension_choosing.popup()

func _on_reload_pressed():
    get_parent().loading(true)
    get_parent().print_debug_message("reloading all branches, please wait...")
    RestHandler.request_user_repository("organization" if current_repo._repository.isInOrganization else "user",
    current_repo._repository.owner.login, current_repo._name)


func _clear() -> void:
    from_branch.clear()
    contents.clear()
    contents_tree.clear()
    branches_opt_btn.clear()
    branches.clear()
    current_branch = ""
    branches.clear()
    branches_contents.clear()
    contents.clear()
    dirs.clear()
    multi_selected.clear()
    commit_sha = ""
    tree_sha = ""

func _on_extraction_overwriting_confirmed():
    pass # Replace with function body.


func _on_extension_option_item_selected(id):
    archive_extension = extension_option.get_item_text(id)

func _on_extension_choosing_confirmed():
    requesting = REQUESTS.PULLING
    var typeball : String = ""
    var typeball_url : String = ""
    match archive_extension:
        ".zip":
            typeball = "zipball"
            typeball_url = current_branch.target.zipballUrl
        ".tar.gz":
            typeball = "tarball"
            typeball_url = current_branch.target.tarballUrl
        _:
            archive_extension = ".zip"
            typeball = "zipball"
            typeball_url = current_branch.target.zipballUrl
    var zipfile = File.new()
    zip_filepath = "res://"+current_repo._name+"-"+current_branch.name+archive_extension
    zipfile.open_compressed(zip_filepath,File.WRITE,File.COMPRESSION_GZIP)
    zipfile.close()
    RestHandler.request_pull_branch(zip_filepath, typeball_url, current_repo._repository.diskUsage)
    get_parent().loading(true)
    get_parent().print_debug_message("pulling from selected branch, a "+archive_extension+" file will automatically be created at the end of the process in 'res://' ...")

func _on_pull_branch_requested() -> void:
    get_parent().print_debug_message(archive_extension+" file created with the selected branch inside, you can find it at -> "+zip_filepath)
    get_parent().loading(false)

# Collaborators ................
func add_collaborator():
    AddCollaborator.popup()

func invite_collaborator():
    var header : Array = UserData.header
    header.append("Content-Length: 0")
    var collaborator_name : String = CollaboratorName.text
    var body : Dictionary = {
            "permission" : CollaboratorPermission.get_item_text(CollaboratorPermission.get_selected_id()),
         }
    if collaborator_name!="" and collaborator_name!=" ":
        RestHandler.request_collaborator(current_repo._repository.owner.login, current_repo._name, collaborator_name, body)
        get_parent().print_debug_message("inviting a user as collaborator...")
    else:
        get_parent().print_debug_message("you must use a valid username", 1)

func _on_collaborator_requested() -> void:
    get_parent().print_debug_message("invitation has been created correctly, the collaborator will receive an accept/decline mail")


func setup_git_lfs():
    var path : String = UserData.directory+current_repo._name+"/"+current_branch.name+"/.gitattributes"
    var extensions : String = ""
    if File.new().file_exists(path) :
        get_parent().print_debug_message(".gitattributes file already set for this repository. You can overwrite it.")
        var gitattributes = File.new()
        gitattributes.open(path,File.READ)
        ExtensionsList.set_text("")
        while not gitattributes.eof_reached():
                extensions += (gitattributes.get_line().split(" "))[0].replace("*","")+"\n"
        ExtensionsList.set_text(extensions)

    SetupDialog.popup()

func _on_cancel_pressed():
    ExtractionRequest.hide()

func _on_gdscript_pressed():
#    gdscript_extraction()
    pass

func _on_python_pressed():
    python_extraction()

func _on_java_pressed():
    java_extraction()

func python_extraction():
    var output = []
    var unzipper_path = ProjectSettings.globalize_path("res://addons/github-integration/resources/extraction/unzip.py")
    var arguments : PoolStringArray = [unzipper_path,ProjectSettings.globalize_path(zip_filepath),ProjectSettings.globalize_path("res://")]
    var err = OS.execute("python",arguments,true)
    get_parent().print_debug_message("archive unzipped in project folder with Python method.")
    ExtractionRequest.hide()

func java_extraction():
    var output = []
    var unzipper_path = ProjectSettings.globalize_path("res://addons/github-integration/resources/extraction/unzipper.jar")
    var arguments : PoolStringArray = ["-jar",unzipper_path,ProjectSettings.globalize_path(zip_filepath),ProjectSettings.globalize_path("res://")]
    var err = OS.execute("java",arguments,true)
    get_parent().print_debug_message("archive unzipped in project folder with Java method.")
    ExtractionRequest.hide()

func _on_whatis_pressed():
    WhatIsDialog.popup()

func _on_learnmore_pressed():
    OS.shell_open("https://git-lfs.github.com")

func _on_setup_git_lfs_confirmed():
    var exstensionList : Array = []
    if ExtensionsList.get_line_count() > 0 and ExtensionsList.get_line(0) != "":
        for exstension in ExtensionsList.get_line_count():
            exstensionList.append(ExtensionsList.get_line(exstension))
    setup_gitlfs(exstensionList)

func setup_gitlfs(extensions : Array):
    var gitattributes = File.new()
    var dir = Directory.new()
    var directory : String = UserData.directory+current_repo._name+"/"+current_branch.name
    if not dir.dir_exists(directory):
        dir.make_dir(directory)
    gitattributes.open(directory+"/.gitattributes",File.WRITE_READ)
    for extension in extensions:
        var tracking : String = "*."+extension+" filter=lfs diff=lfs merge=lfs -text"
        gitattributes.store_line(tracking)
    gitattributes.close()
    get_parent().print_debug_message("New .gitattributes created with the file extensions you want to track. It will be uploaded to you repository during the next push.")









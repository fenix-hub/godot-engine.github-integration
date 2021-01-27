tool
class_name RepositoryItem
extends PanelContainer


signal repo_selected(repo)
signal repo_clicked(repo)

onready var Name = $Repository/Name
onready var Stars = $Repository/Stars
onready var Forks = $Repository/Forks
onready var Collaborator = $Repository/Name/Collaborator
onready var BG = $BG

var _name : String
var _stars : int
var _forks : int
var _metadata : Dictionary
var _repository : Dictionary

func _ready():
    Stars.get_node("Icon").set_texture(IconLoaderGithub.load_icon_from_name("stars"))
    Forks.get_node("Icon").set_texture(IconLoaderGithub.load_icon_from_name("forks"))

func set_repository(repository : Dictionary):
    _repository = repository
    _name = str(repository.name)
    name = _name
    _stars = repository.stargazerCount
    _forks = repository.forkCount
    
    # Check collaboration
    var is_collaborator : bool = repository.owner.login != UserData.USER.login
    
    Name.get_node("Text").set_text(_name)
    Stars.get_node("Amount").set_text("Stars: "+str(_stars))
    Forks.get_node("Amount").set_text("Forks: "+str(_forks))
    
    var repo_icon : ImageTexture
    if repository.isPrivate:
        repo_icon = IconLoaderGithub.load_icon_from_name("lock")
        Name.get_node("Icon").set_tooltip("Private")
    else:
        repo_icon = IconLoaderGithub.load_icon_from_name("repos")
        Name.get_node("Icon").set_tooltip("Public")
        if repository.isFork:
            repo_icon = IconLoaderGithub.load_icon_from_name("forks")
            Name.get_node("Icon").set_tooltip("Forked")
    if is_collaborator:
        Collaborator.texture = IconLoaderGithub.load_icon_from_name("collaboration")
        Collaborator.set_tooltip("Collaboration")
    if repository.isInOrganization:
        Collaborator.texture = IconLoaderGithub.load_icon_from_name("organization")
        Collaborator.set_tooltip("Organization")
    Name.get_node("Icon").set_texture(repo_icon)

func deselect():
    BG.hide()

func _on_RepositoryItem_gui_input(event):
    if event is InputEventMouseButton:
        if event.is_pressed() and event.button_index == 1:
            BG.show()
            emit_signal("repo_clicked", self)
        if event.doubleclick:
            emit_signal("repo_selected", self)

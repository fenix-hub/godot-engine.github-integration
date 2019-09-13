tool
extends Control

var plugin_name = "[Github Integration] >> "

onready var SignIn = $SingIn
onready var UserPanel = $UserPanel
onready var NewRepo = $NewRepo
onready var CommitRepo = $Commit
onready var Repo = $Repo
onready var Commit = $Commit


func _ready():
	$version.text = "v 0.2.5"
	Repo.hide()
	NewRepo.hide()
	SignIn.show()
	SignIn.connect("signed",self,"signed")
	UserPanel.hide()
	Commit.hide()

func signed() -> void:
	UserPanel.load_panel()
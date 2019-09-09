tool
extends Control

var plugin_name = "[Github Integration] >> "

onready var SignIn = $"Sign-in"
onready var UserPanel = $UserPanel
onready var NewRepo = $NewRepo
onready var CommitRepo = $Commit
onready var Repo = $Repo

var user_logged 
var user_data



func _ready():
	Repo.hide()
	NewRepo.hide()
	SignIn.show()
	SignIn.connect("signed",self,"signed")
	UserPanel.hide()

func signed(user : Dictionary, avatar : String) -> void:
	UserPanel.load_panel(user,avatar)

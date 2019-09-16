# ----------------------------------------------
#            ~{ GitHub Integration }~
# [Author] Nicolò "fenix" Santilio 
# [github] fenix-hub/godot-engine.github-integration
# [version] 0.2.9
# [date] 09.13.2019





# -----------------------------------------------

tool
extends Control

var plugin_version
var plugin_name

onready var SignIn = $SingIn
onready var UserPanel = $UserPanel
onready var NewRepo = $NewRepo
onready var CommitRepo = $Commit
onready var Repo = $Repo
onready var Commit = $Commit


func _ready():

	var config =  ConfigFile.new()
	var err = config.load("res://addons/github-integration/plugin.cfg")
	if err == OK:
		plugin_version = config.get_value("plugin","version")
		plugin_name = "["+config.get_value("plugin","name")+"] >> "
	
	$version.text = "v "+plugin_version
	Repo.hide()
	NewRepo.hide()
	SignIn.show()
	SignIn.connect("signed",self,"signed")
	UserPanel.hide()
	Commit.hide()

func signed() -> void:
	UserPanel.load_panel()
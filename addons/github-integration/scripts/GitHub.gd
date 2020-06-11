# ----------------------------------------------
#            ~{ GitHub Integration }~
# [Author] Nicolò "fenix" Santilio 
# [github] fenix-hub/godot-engine.github-integration
# [version] 0.2.9
# [date] 09.13.2019





# -----------------------------------------------

tool
extends Control

onready var SignIn = $SingIn
onready var UserPanel = $UserPanel
onready var NewRepo = $NewRepo
onready var CommitRepo = $Commit
onready var Repo = $Repo
onready var Gist = $Gist
onready var Commit = $Commit
onready var LoadNode = $loading
onready var Version = $datas/version
onready var Debug = $datas/debug
onready var ConnectionIcon : TextureRect = $datas/connection

var connection_status : Array = [
	IconLoaderGithub.load_icon_from_name("searchconnection"),
	IconLoaderGithub.load_icon_from_name("noconnection"),
	IconLoaderGithub.load_icon_from_name("connection")
]

var plugin_version
var plugin_name
var debug : bool


func _ready():
	ConnectionIcon.set_texture(connection_status[0])
	
	debug = true
	LoadNode.hide()
	Debug.set_pressed(debug)
	
	var config =  ConfigFile.new()
	var err = config.load("res://addons/github-integration/plugin.cfg")
	if err == OK:
		plugin_version = config.get_value("plugin","version")
		plugin_name = "["+config.get_value("plugin","name")+"] >> "
	
	Version.text = "v "+plugin_version
	Repo.hide()
	NewRepo.hide()
	SignIn.show()
	SignIn.connect("signed",self,"signed")
	UserPanel.hide()
	Commit.hide()
	
	match RestHandler.check_connection():
		true:
			SignIn.btnSignIn.set_disabled(false)
			ConnectionIcon.set_texture(connection_status[2])
			ConnectionIcon.set_tooltip("Connected to GitHub API")
		false:
			SignIn.btnSignIn.set_disabled(true)
			ConnectionIcon.set_texture(connection_status[1])
			ConnectionIcon.set_tooltip("Can't connect to GitHub API, check your internet connection or API status")

func loading(value : bool) -> void:
	LoadNode.visible = value

func show_loading_progress(value : float,  max_value : float) -> void:
	LoadNode.show_progress(value,max_value)

func hide_loading_progress():
	LoadNode.hide_progress()

func show_number(value : float, type : String) -> void:
	LoadNode.show_number(value,type)

func hide_number():
	LoadNode.hide_number()

func signed() -> void:
	UserPanel.load_panel()

func print_debug_message(message : String = "",type : int = 0):
	if debug == true:
		match type:
			0:
				print(plugin_name,message)
			1:
				printerr(plugin_name,message)

func _on_debug_toggled(button_pressed):
	debug = button_pressed


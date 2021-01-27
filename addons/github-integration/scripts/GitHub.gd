# ----------------------------------------------
#            ~{ GitHub Integration }~
# [Author] Nicolò "fenix" Santilio 
# [github] fenix-hub/godot-engine.github-integration
# [version] 0.2.9
# [date] 09.13.2019

# -----------------------------------------------

tool
extends Control

onready var VersionCheck : HTTPRequest = $VersionCheck

onready var SignIn : Control = $SingIn
onready var UserPanel : Control = $UserPanel
onready var CommitRepo : Control = $Commit
onready var Repo : Control = $Repo
onready var Gist : Control = $Gist
onready var Commit : Control = $Commit
onready var LoadNode : Control = $loading
onready var Version : Control = $Header/datas/version
onready var ConnectionIcon : TextureRect = $Header/datas/connection
onready var Header : Control = $Header
onready var RestartConnection = Header.get_node("datas/restart_connection")
onready var Menu : PopupMenu = $Header/datas/Menu.get_popup()
onready var Notifications : Control = $Notifications

var user_avatar : ImageTexture = ImageTexture.new()
var user_img = Image.new()

var connection_status : Array = [
    IconLoaderGithub.load_icon_from_name("searchconnection"),
    IconLoaderGithub.load_icon_from_name("noconnection"),
    IconLoaderGithub.load_icon_from_name("connection")
]

var plugin_version : String 
var plugin_name : String

# Load the configuration file for this plugin to fetch some info
func load_config() -> void:
    var config =  ConfigFile.new()
    var err = config.load("res://addons/github-integration/plugin.cfg")
    if err == OK:
        plugin_version = config.get_value("plugin","version")
        plugin_name = "[%s] >> " % config.get_value("plugin","name")

func connect_signals() -> void:
    Menu.connect("index_pressed", self, "menu_item_pressed")
    RestartConnection.connect("pressed",self,"check_connection")
    VersionCheck.connect("request_completed",self,"_on_version_check")
    SignIn.connect("signed",self,"signed")
    UserPanel.connect("completed_loading", SignIn, "_on_completed_loading")
    UserPanel.connect("loaded_gists", Gist, "_on_loaded_repositories")
    Header.connect("load_invitations", Notifications, "_on_load_invitations_list")
    Header.notifications_btn.connect("pressed", Notifications, "_open_notifications")
    Notifications.connect("add_notifications", Header, "_on_add_notifications")

func hide_nodes() -> void:
    Repo.hide()
    SignIn.show()
    UserPanel.hide()
    Commit.hide()
    LoadNode.hide()

func _ready():
    connect_signals()
    hide_nodes()
    # Load Config file
    load_config()
    Version.text = "v "+plugin_version
    
    ConnectionIcon.set_texture(connection_status[0])
    ConnectionIcon.use_parent_material = false
    ConnectionIcon.material.set("shader_param/speed", 3)
    
    # Check the connection with the API
    RestHandler.check_connection()
    # Yield until the "_check_connection" function returns a value
    var connection = yield(RestHandler, "_check_connection")
    match connection:
        true:
            ConnectionIcon.set_texture(connection_status[2])
            ConnectionIcon.set_tooltip("Connected to GitHub API")
            RestartConnection.hide()
        false:
            ConnectionIcon.set_texture(connection_status[1])
            ConnectionIcon.set_tooltip("Can't connect to GitHub API, check your internet connection or API status")
            RestartConnection.show()
    ConnectionIcon.use_parent_material = true
    ConnectionIcon.material.set("shader_param/speed", 0)
    
    Menu.set_item_checked(0, PluginSettings.debug)
    Menu.set_item_checked(1, PluginSettings.auto_log)
    # Check the plugin verison
    VersionCheck.request("https://api.github.com/repos/fenix-hub/godot-engine.github-integration/tags",[],false,HTTPClient.METHOD_GET,"")
    
    if PluginSettings.auto_log:
        SignIn.sign_in()
    
    set_darkmode(PluginSettings.darkmode)

# Show or hide the loading screen
func loading(value : bool) -> void:
    LoadNode.visible = value

# Show the loading process, giving the current value and a maximum value
func show_loading_progress(value : float,  max_value : float) -> void:
    LoadNode.show_progress(value,max_value)

func hide_loading_progress():
    LoadNode.hide_progress()

func show_number(value : float, type : String) -> void:
    LoadNode.show_number(value,type)

func hide_number() -> void:
    LoadNode.hide_number()

# If User Signed
func signed() -> void:
    UserPanel.load_panel()
    set_avatar(UserData.AVATAR)
    set_username(UserData.USER.login)
    yield(UserPanel, "completed_loading")
    Notifications.request_notifications()

# Print a debug message if the debug setting is set to "true", with a debug type from 0 to 2
func print_debug_message(message : String = "", type : int = 0) -> void:
    if PluginSettings.debug == true:
            match type:
                0:
                        print(plugin_name,message)
                1:
                        printerr(plugin_name,message)
                2:
                        push_warning(plugin_name+message)
    if type != 1: set_loading_message(message)

func set_loading_message(message : String):
    LoadNode.message.set_text(message)

# Control logic for each item in the plugin menu
func menu_item_pressed(id : int) -> void:
    match id:
#		0:
#			_on_debug_toggled(!Menu.is_item_checked(id))
#		1:
#			_on_autologin_toggled(!Menu.is_item_checked(id))
        0:
            OS.shell_open("https://github.com/fenix-hub/godot-engine.github-integration/wiki")
        1:
            logout()
        2:
            set_darkmode(!Menu.is_item_checked(id))

# Logout function
func logout():
    set_avatar(IconLoaderGithub.load_icon_from_name("circle"))
    set_username("user")
    SignIn.show()
    UserPanel._clear()
    UserPanel.hide()
    Repo.hide()
    Commit.hide()
    Gist.hide()
    Notifications._clear()
    Notifications.hide()
    SignIn.Mail.text = ""
    SignIn.Token.text = ""
    UserData.logout_user()

# Set to darkmode each single Control
func set_darkmode(darkmode : bool) -> void:
    PluginSettings.set_darkmode(darkmode)
    SignIn.set_darkmode(darkmode)
    UserPanel.set_darkmode(darkmode)
    Repo.set_darkmode(darkmode)
    Commit.set_darkmode(darkmode)
    Gist.set_darkmode(darkmode)
    Header.set_darkmode(darkmode)
    Notifications.set_darkmode(darkmode)

func set_avatar(avatar : ImageTexture) -> void:
    $Header/datas/avatar.texture = avatar

func set_username(username : String) -> void:
    $Header/datas/user.text = username

# If the plugin version has been checked
func _on_version_check(result, response_code, headers, body ) -> void:
    if result == 0:
        if response_code == 200:
            var tags : Array = JSON.parse(body.get_string_from_utf8()).result
            var first_tag : Dictionary = tags[0] as Dictionary
            if first_tag.name != ("v"+plugin_version):
                print_debug_message("a new plugin version has been found, current version is %s and new version is %s" % [("v"+plugin_version), first_tag.name],1)

tool
extends Control

signal signed()

onready var Mail : LineEdit = $FieldContainer/signin_panel/Mail
onready var Token : LineEdit = $FieldContainer/signin_panel/Password
onready var Error : Label = $FieldContainer/signin_panel/error
onready var LogfileIcon : Label = $FieldContainer/signin_panel/HBoxContainer3/logfile
onready var btnSignIn : Button = $FieldContainer/signin_panel/HBoxContainer3/btnSignIn
onready var btnCreateToken : LinkButton = $FieldContainer/signin_panel/Token/btnCreateToken
onready var DeleteDataBtn : Button = $FieldContainer/signin_panel/DeleteDataBtn
onready var DeletePopup : ConfirmationDialog = $DeletePopup
onready var DeleteHover : ColorRect = $DeleteHover

var mail : String 
var token : String
var auth : String
enum REQUESTS { LOGIN = 0, AVATAR = 1, END = -1 , USER = 2 }
var requesting : int
var user_data : Dictionary

var logfile : bool = false

onready var Client : HTTPClient = HTTPClient.new()

var userdata : bool = false

func connect_signals() -> void:
	Mail.connect("text_changed", self, "_on_mail_changed")
	Token.connect("text_changed", self, "_on_token_changed")
	
	btnSignIn.connect("pressed",self,"sign_in")
	btnCreateToken.connect("pressed",self,"create_token")
	
	DeleteDataBtn.connect("pressed",self,"_on_delete_pressed")
	DeletePopup.connect("confirmed",self,"_on_delete_confirm")
	DeletePopup.connect("popup_hide", self, "close_popup")
	
	# Connections to the RestHandler
	RestHandler.connect("request_failed", self, "_on_request_failed")
	RestHandler.connect("user_requested", self, "_on_user_requested")
	RestHandler.connect("user_avatar_requested", self, "_on_user_avatar_requested")

func _ready() -> void:
	connect_signals()
	LogfileIcon.hide()
	Error.hide()
	
	DeleteDataBtn.set_disabled(true)
	
	yield(get_tree(),"idle_frame")
	check_user()

func _on_userdata_ready():
	userdata = true

func check_user():
	if UserData.user_exists():
		logfile = true
		LogfileIcon.show()
		DeleteDataBtn.disabled = false
		Mail.text = "<logfile.mail>"
		_on_mail_changed(Mail.text)
		Token.text = "<logfile.password>"
		_on_token_changed(Token.text)
		get_parent().print_debug_message("user data found, just sign in without using your credentials.")
		btnSignIn.set_disabled(false)

func set_darkmode(darkmode : bool) -> void:
	if darkmode:
		$BG.color = "#24292e"
		set_theme(load("res://addons/github-integration/resources/themes/GitHubTheme-Dark.tres"))
	else:
		$BG.color = "#f6f8fa"
		set_theme(load("res://addons/github-integration/resources/themes/GitHubTheme.tres"))

func create_token() -> void:
	OS.shell_open("https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line")

func sign_in() -> void:
	get_parent().print_debug_message("logging in...")
	
	if !logfile:
		# If there isn't a logfile inside user's folder
		mail = Mail.text
		token = Token.text
		if mail!="" and token!="":
			get_parent().loading(true)
			auth = Marshalls.utf8_to_base64(mail+":"+token)
			RestHandler.request_user(token)
		else:
			get_parent().print_debug_message("Bad credentials - you need to insert your e-mail and token.", 1)
	else:
		# If there is a logfile
		get_parent().loading(true)
		UserData.load_user()
		emit_signal("signed")

func _on_completed_loading():
	get_parent().loading(false)
	hide()

func _on_request_failed(request_code : int, error_body : Dictionary) -> void:
	match request_code:
		RestHandler.REQUESTS.USER:
			set_process(false)
			get_parent().loading(true)
			Error.show()
			Error.text = "Error: "+str(error_body.message)
			get_parent().print_debug_message("Bad credentials - incorrect username or token.",1)
			get_parent().loading(false)

func _on_user_requested(user : Dictionary) -> void:
	Error.hide()
	user_data = user
	RestHandler.request_user_avatar(user_data.avatar_url)

func _on_user_avatar_requested(user_avatar : PoolByteArray) -> void:
	get_parent().loading(true)
	UserData.save(user_data, user_avatar, auth, token, mail) 
	emit_signal("signed")
	DeleteDataBtn.set_disabled(false)

func _on_singup_pressed():
	OS.shell_open("https://github.com/join?source=header-home")

func _on_wiki_pressed():
	OS.shell_open("https://github.com/fenix-hub/godot-engine.github-integration/wiki")

func _on_delete_pressed():
	DeletePopup.popup()
	DeleteHover.show()

func _on_delete_confirm():
	delete_user()

func delete_user():
	UserData.delete_user()
	logfile = false
	LogfileIcon.hide()
	DeleteDataBtn.disabled = true
	Mail.text = ""
	Token.text = ""

func close_popup() :
	DeleteHover.hide()

func _on_mail_changed(text : String):
	if not text in [""," "] and not Token.text in [""," "]: btnSignIn.set_disabled(false)
	else: if not logfile: btnSignIn.set_disabled(true)

func _on_token_changed(text : String):
	if not text in [""," "] and not Mail.text in [""," "]: btnSignIn.set_disabled(false)
	else: if not logfile: btnSignIn.set_disabled(true)

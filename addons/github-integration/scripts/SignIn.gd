tool
extends Control

signal signed()

onready var Mail : LineEdit = $signin_panel/HBoxContainer/Mail
onready var Token : LineEdit = $signin_panel/HBoxContainer2/Password
onready var Error = $signin_panel/error
onready var logfile_icon = $signin_panel/HBoxContainer3/logfile

onready var btnSignIn = $signin_panel/HBoxContainer3/btnSignIn
onready var btnCreateToken = $signin_panel/HBoxContainer3/btnCreateToken

var mail : String 
var token : String
var signin_request = HTTPRequest.new()
var download_image = HTTPRequest.new()
var auth
enum REQUESTS { LOGIN = 0, AVATAR = 1, END = -1 }
var requesting
var user_data

var logfile = false

onready var Client : HTTPClient = HTTPClient.new()

func _ready():
	btnSignIn.set_disabled(true)
	
	logfile_icon.hide()
	Error.hide()
	btnSignIn.connect("pressed",self,"sign_in")
	btnCreateToken.connect("pressed",self,"create_token")
	call_deferred("add_child",signin_request)
	call_deferred("add_child",download_image)
	signin_request.connect("request_completed",self,"signin_completed")
	download_image.connect("request_completed",self,"signin_completed")
	
	if UserData.load_user().size() > 0:
		logfile = true
		logfile_icon.show()

func create_token():
	OS.shell_open("https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line")

func sign_in():
	get_parent().print_debug_message("logging in...")
	
	if !logfile:
		mail = Mail.text
		token = Token.text
		if mail!="" and token!="":
			get_parent().loading(true)
			auth = Marshalls.utf8_to_base64(mail+":"+token)
			requesting = REQUESTS.LOGIN
			signin_request.request("https://api.github.com/user",["Authorization: token "+token],false,HTTPClient.METHOD_GET,"")
		else:
			get_parent().print_debug_message("Bad credentials - you need to insert your e-mail and token.",1)
	else:
		Mail.text = "<logfile.mail>"
		Token.text = "<logfile.password>"
		get_parent().loading(true)
		emit_signal("signed")
		yield(get_parent().UserPanel,"completed_loading")
		requesting = REQUESTS.END
		get_parent().loading(false)
		hide()

func signin_completed(result, response_code, headers, body ):
	if result == 0:
		match requesting:
			REQUESTS.LOGIN:
				if response_code == 200:
					Error.hide()
					user_data = JSON.parse(body.get_string_from_utf8()).result
					download_image.request(user_data.avatar_url)
					requesting = REQUESTS.AVATAR
				elif response_code == 401:
					set_process(false)
					get_parent().loading(true)
					Error.show()
					Error.text = "Error: "+str((JSON.parse(body.get_string_from_utf8()).result).message)
					get_parent().print_debug_message("Bad credentials - incorrect username or token.",1)
					get_parent().loading(false)
			REQUESTS.AVATAR:
				UserData.save(user_data,body,auth,token,mail) 
				emit_signal("signed")
				yield(get_parent().UserPanel,"completed_loading")
				requesting = REQUESTS.END
				get_parent().loading(true)
				hide()
				get_parent().loading(false)

func _on_singup_pressed():
	OS.shell_open("https://github.com/join?source=header-home")


func _on_wiki_pressed():
	OS.shell_open("https://github.com/fenix-hub/godot-engine.github-integration/wiki")

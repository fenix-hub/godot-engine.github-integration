# ----------------------------------------------
#            ~{ GitHub Integration }~
# [Author] Nicolò "fenix" Santilio 
# [github] fenix-hub/godot-engine.github-integration
# [version] 0.2.9
# [date] 09.13.2019





# -----------------------------------------------

tool
extends Control

signal signed()

onready var Mail : LineEdit = $signin_panel/HBoxContainer/Mail
onready var Token : LineEdit = $signin_panel/HBoxContainer2/Password
onready var Error = $signin_panel/error
onready var Loading = $signin_panel/loading
onready var logfile_lbl = $signin_panel/HBoxContainer3/logfile

var mail : String 
var password : String
var signin_request = HTTPRequest.new()
var download_image = HTTPRequest.new()
var auth
enum REQUESTS { LOGIN = 0, AVATAR = 1, END = -1 }
var requesting
var user_data

var logfile = false


func _ready():
	logfile_lbl.hide()
	set_process(false)
	Loading.hide()
	Error.hide()
	$signin_panel/HBoxContainer3/btnSignIn.connect("pressed",self,"sign_in")
	$signin_panel/HBoxContainer3/btnCreateToken.connect("pressed",self,"create_token")
	call_deferred("add_child",signin_request)
	call_deferred("add_child",download_image)
	signin_request.connect("request_completed",self,"signin_completed")
	download_image.connect("request_completed",self,"signin_completed")
	
	if UserData.load_user():
		logfile = true
		logfile_lbl.show()
	else:
		logfile_lbl.hide()


func create_token():
	OS.shell_open("https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line")

func sign_in():
	
	
	if !logfile:
		print(get_parent().plugin_name,"no logfiles found, signing in for the first time.")
		mail = Mail.text
		password = Token.text
		if mail!="" and password!="":
			Loading.show()
			auth = Marshalls.utf8_to_base64(mail+":"+password)
			requesting = REQUESTS.LOGIN
			signin_request.request("https://api.github.com/user",["Authorization: Basic "+auth],false,HTTPClient.METHOD_GET,"")
	else:
		Mail.text = UserData.MAIL
		Token.text = UserData.PWD
		print(get_parent().plugin_name,"found logfile, signing in.")
		Loading.show()
		emit_signal("signed")
		yield(get_parent().UserPanel,"completed_loading")
		requesting = REQUESTS.END
		Loading.hide()
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
					Loading.hide()
					Error.show()
					Error.text = "Error: "+str((JSON.parse(body.get_string_from_utf8()).result).message)
			REQUESTS.AVATAR:
				
				UserData.save(user_data,body,auth,password,mail) 
				emit_signal("signed")
				yield(get_parent().UserPanel,"completed_loading")
				requesting = REQUESTS.END
				Loading.hide()
				hide()


func _on_loading_visibility_changed():
	var Mat = Loading.get_material()
	if Loading.visible:
		Mat.set_shader_param("speed",5)
	else:
		Mat.set_shader_param("speed",0)

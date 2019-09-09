tool
extends Control

# ----------------------------------------------
#            ~{ GitHub Integration }~
# [Author] Nicolò "fenix" Santilio 
# [github] fenix-hub/godot.git-integration
# [version] 0.0.1
# [date] 2019 - 


# https://api.github.com/user --> request authorization


# -----------------------------------------------

signal signed(user,avatar)

onready var Username : LineEdit = $"Sign-in/HBoxContainer/Username"
onready var Token : LineEdit = $"Sign-in/HBoxContainer2/Password"
onready var Loading = $"Sign-in/Loading"
onready var Error = $"Sign-in/error"

var username : String 
var password : String
var signin_request = HTTPRequest.new()
var download_image = HTTPRequest.new()
var auth
enum REQUESTS { LOGIN = 0, AVATAR = 1, END = -1 }
var requesting
var user_data

func _ready():
	Loading.hide()
	Error.hide()
	$"Sign-in/HBoxContainer3/sign-in".connect("pressed",self,"sign_in")
	$"Sign-in/HBoxContainer3/create-token".connect("pressed",self,"create_token")
	call_deferred("add_child",signin_request)
	call_deferred("add_child",download_image)
	signin_request.connect("request_completed",self,"signin_completed")
	download_image.connect("request_completed",self,"signin_completed")
	


func create_token():
	OS.shell_open("https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line")

func _process(delta):
	loading_anim(delta)

func sign_in():
	username = Username.text
	password = Token.text
	if username!="" and password!="":
		Loading.show()
		set_process(true)
		auth = Marshalls.utf8_to_base64(username+":"+password)
		requesting = REQUESTS.LOGIN
		signin_request.request("https://api.github.com/user",["Authorization: Basic "+auth],false,HTTPClient.METHOD_GET,"")

func signin_completed(result, response_code, headers, body ):
	if result == 0:
		match requesting:
			REQUESTS.LOGIN:
				if response_code == 200:
					Error.hide()
					get_parent().user_logged = auth
					user_data = JSON.parse(body.get_string_from_utf8()).result
					get_parent().user_data = user_data
					download_image.request(user_data.avatar_url)
					requesting = REQUESTS.AVATAR
				elif response_code == 401:
					set_process(false)
					Loading.hide()
					Error.show()
					Error.text = "Error: "+str((JSON.parse(body.get_string_from_utf8()).result).message)
			REQUESTS.AVATAR:
				var avatar = Image.new()
				avatar.load_png_from_buffer(body)
				avatar.save_png("res://addons/github-integration/user/avatar.png")
				emit_signal("signed",user_data,"res://addons/github-integration/user/avatar.png")
				yield(get_parent().UserPanel,"completed_loading")
				requesting = REQUESTS.END
				Loading.hide()
				hide()
				set_process(false)

func loading_anim(delta):
	Loading.rect_rotation = (Vector2(Loading.rect_rotation,0).linear_interpolate(Vector2(360,0), 4 * delta)).x
	if Loading.rect_rotation > 330:
		Loading.rect_rotation = 0

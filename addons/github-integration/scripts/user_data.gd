tool
extends Node

# saves and loads user datas from custom folder in user://github_integration/user_data.ud

var directory = "user://github_integration/"
var file_name = "user_data.ud"
var avatar_name = "avatar.png"

var USER : Dictionary
var AUTH : String
var AVATAR : ImageTexture
var PWD : String
var MAIL : String

var header : Array

func _ready():
	pass # Replace with function body.

func save(user : Dictionary, avatar : PoolByteArray, auth : String, pwd : String, mail : String) -> void:
	
	var dir = Directory.new()
	var file = File.new()
	var img = Image.new()
	
	if not dir.dir_exists(directory):
		dir.make_dir(directory)
		print("[GitHub Integration] >> ","made custom directory in user folder, it is called 'github-integration'")
		
	if user!=null:
		var err = file.open(directory+file_name,File.WRITE)
		USER = user
		AUTH = auth
		PWD = pwd
		MAIL = mail
		var formatting : PoolStringArray
		formatting.append(auth)                     #0
		formatting.append(mail)                     #1
		formatting.append(pwd)                      #2
		formatting.append(JSON.print(user))         #3
		file.store_csv_line(formatting)
		file.close()
		print("[GitHub Integration] >> ","saved user datas in user folder")
		
	
	if avatar!=null:
		img.load_png_from_buffer(avatar)
		img.save_png(directory+avatar_name)
		print("[GitHub Integration] >> ","saved avatar in user folder")
		
		print(avatar)
		var av : Image = Image.new()
		av.load(directory+avatar_name)
		var img_text : ImageTexture = ImageTexture.new()
		img_text.create_from_image(av)
		AVATAR = img_text
	
	header = ["Authorization: Basic "+AUTH]

func load_user() -> PoolStringArray :
	var file = File.new()
	var content : PoolStringArray
	
	if file.file_exists(directory+file_name) :
		file.open(directory+file_name,File.READ)
		content = file.get_csv_line()
		AUTH = content[0]
		MAIL = content[1]
		PWD = content[2]
		USER = JSON.parse(content[3]).result
		
		var av : Image = Image.new()
		av.load(directory+avatar_name)
		var img_text : ImageTexture = ImageTexture.new()
		img_text.create_from_image(av)
		
		
		AVATAR = img_text
		header = ["Authorization: Basic "+UserData.AUTH]
	
	return content
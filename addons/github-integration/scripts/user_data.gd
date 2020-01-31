# ----------------------------------------------
#            ~{ GitHub Integration }~
# [Author] Nicolò "fenix" Santilio 
# [github] fenix-hub/godot-engine.github-integration
# [version] 0.2.9
# [date] 09.13.2019





# -----------------------------------------------

tool
extends Node

# saves and loads user datas from custom folder in user://github_integration/user_data.ud

var directory : String = ""
var directory_name = "github_integration"
var file_name = "user_data.ud"
var avatar_name = "avatar.png"

var USER : Dictionary

# --- on the USER usage
# login = username
# avatar
# id

var AUTH : String
var AVATAR : ImageTexture
var TOKEN : String
var MAIL : String

var header : Array = [""]
var gitlfs_header : Array = [""]
var gitlfs_request : String = ".git/info/lfs/objects/batch"

var plugin_version : String = "0.8.2"

func _ready():
	directory = ProjectSettings.globalize_path("user://").replace("app_userdata/"+ProjectSettings.get_setting('application/config/name')+"/",directory_name)+"/"

func save(user : Dictionary, avatar : PoolByteArray, auth : String, token : String, mail : String) -> void:
	
	var dir = Directory.new()
	var file = File.new()
	var img = Image.new()
	
	if not dir.dir_exists(directory):
		dir.make_dir(directory)
		print("[GitHub Integration] >> ","made custom directory in user folder, it is placed at ", directory)
		
	if user!=null:
		var err = file.open_encrypted_with_pass(directory+file_name,File.WRITE,OS.get_unique_id())
		USER = user
		AUTH = auth
		TOKEN = token
		MAIL = mail
		var formatting : PoolStringArray
		formatting.append(auth)                     #0
		formatting.append(mail)                     #1
		formatting.append(token)                    #2
		formatting.append(JSON.print(user))         #3
		formatting.append(plugin_version)           #4
		file.store_csv_line(formatting)
		file.close()
		print("[GitHub Integration] >> ","saved user datas in user folder")
		
	
	if avatar!=null:
		img.load_png_from_buffer(avatar)
		img.save_png(directory+avatar_name)
		print("[GitHub Integration] >> ","saved avatar in user folder")
		var av : Image = Image.new()
		av.load(directory+avatar_name)
		var img_text : ImageTexture = ImageTexture.new()
		img_text.create_from_image(av)
		AVATAR = img_text
	
	header = ["Authorization: token "+token]

func load_user() -> PoolStringArray :
	directory = ProjectSettings.globalize_path("user://").replace("app_userdata/"+ProjectSettings.get_setting('application/config/name')+"/",directory_name)+"/"
	var file = File.new()
	var content : PoolStringArray
	
	print("[GitHub Integration] >> loading user profile, checking for existing logfile...")
	
	if file.file_exists(directory+file_name) :
		print("[GitHub Integration] >> ","logfile found, fetching datas..")
		file.open_encrypted_with_pass(directory+file_name,File.READ,OS.get_unique_id())
		content = file.get_csv_line()
		
		if content.size() < 5:
			printerr("[GitHub Integration] >> ","this log file belongs to an older version of this plugin and will not support the mail/password login deprecation, so it will be deleted. Please, insert your credentials again.")
			file.close()
			var dir = Directory.new()
			dir.remove(directory+file_name)
			content = []
			return content
		
		AUTH = content[0]
		MAIL = content[1]
		TOKEN = content[2]
		USER = JSON.parse(content[3]).result
		
		var av : Image = Image.new()
		av.load(directory+avatar_name)
		var img_text : ImageTexture = ImageTexture.new()
		img_text.create_from_image(av)
		
		
		AVATAR = img_text
		header = ["Authorization: token "+TOKEN]
		gitlfs_header = [
			"Accept: application/vnd.git-lfs+json",
			"Content-Type: application/vnd.git-lfs+json"]
		gitlfs_header.append(header[0])
	else:
		printerr("[GitHub Integration] >> ","no logfile found, log in for the first time to create a logfile.")
	
	return content


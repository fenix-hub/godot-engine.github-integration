tool
extends HBoxContainer
class_name ContributorClass

onready var avatar_texture : TextureRect = $Avatar
onready var login_lbl : Label = $Login
onready var name_lbl : Label = $Name
onready var client : HTTPRequest = $HTTPRequest

var is_downloading : bool = false

var _avatar : String
var _name : String
var _login : String

func _ready() -> void:
	client.connect("request_completed", self, "_on_request_completed")
	pass
#	RestHandler.connect("user_contributor_requested", self, "_on_contributor_avatar_requested")

func load_contributor(contributor_login : String, contributor_name : String = "", contributor_avatar : String = "") -> void:
	set_contributor_login(contributor_login)
	set_contributor_name(contributor_name)
	set_contributor_avatar(contributor_avatar)

func set_contributor_login(l : String) -> void:
	_login = l
	login_lbl.set_text(_login)

func set_contributor_name(n : String) -> void:
	_name = n
	name_lbl.set_text(_name)

func set_contributor_avatar(a : String) -> void:
	_avatar = a
	client.request(_avatar)
	is_downloading = true

func _process(delta):
	if is_downloading: pass#print(client.get_downloaded_bytes()/client.get_body_size()*100, " %")

func _on_request_completed(result: int, response_code: int, headers: PoolStringArray, avatar: PoolByteArray) -> void:
	if result == 0:
		if response_code == 200:
			var image : Image = Image.new()
			var extension : String = avatar.subarray(0,1).hex_encode()
			match extension:
				"ffd8":
					image.load_jpg_from_buffer(avatar)
				"8950":
					image.load_png_from_buffer(avatar)
			var texture : ImageTexture = ImageTexture.new()
			texture.create_from_image(image)
			avatar_texture.set_texture(texture)
	is_downloading = false

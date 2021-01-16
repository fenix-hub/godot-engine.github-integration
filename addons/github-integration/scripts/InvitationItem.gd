tool
class_name InvitationItem
extends HBoxContainer

onready var user_lbl : LinkButton = $User
onready var repository_lbl : LinkButton = $Repository
onready var permissions_lbl : Label = $Permissions
onready var client : HTTPRequest = $HTTPRequest
onready var avatar_texture : TextureRect = $Avatar
onready var accept_btn : Button = $AcceptBtn
onready var decline_btn : Button = $DeclineBtn
onready var result_lbl : Label = $Result

var invitation_id : int
var user_invitation : String
var repository_invitation : String 
var avatar_invitation : String
var user_url : String
var repository_url : String

signal set_to_load_next(to_load)
signal add_notifications(amount)
signal invitation_accepted()
signal invitation_declined()

func _ready():
	user_lbl.connect("pressed", self, "_on_user_pressed")
	repository_lbl.connect("pressed", self, "_on_repository_pressed")
	client.connect("request_completed", self, "_on_request_completed")
	accept_btn.connect("pressed", self, "_on_invite_accept")
	decline_btn.connect("pressed", self, "_on_invite_decline")
	RestHandler.connect("invitation_accepted", self, "_on_invitation_accepted")
	RestHandler.connect("invitation_declined", self, "_on_invitation_declined")

func load_invitation(invitation : Dictionary) -> void:
	invitation_id = invitation.id
	set_user_invitation(invitation.inviter.login)
	set_repository_invitation(invitation.repository.name)
	set_avatar_invitation(invitation.inviter.avatar_url)
	user_url = invitation.inviter.html_url
	repository_url = invitation.repository.html_url
	permissions_lbl.set_text(invitation.permissions)

func set_user_invitation(user : String) -> void:
	user_invitation = user
	user_lbl.set_text(user_invitation)

func set_repository_invitation(repository : String):
	repository_invitation = repository
	repository_lbl.set_text(repository_invitation)

func set_avatar_invitation(avatar : String):
	avatar_invitation = avatar
	client.request(avatar)

func _on_user_pressed():
	OS.shell_open(user_url)

func _on_repository_pressed():
	OS.shell_open(repository_url)

func _on_invite_accept():
	RestHandler.request_accept_invitation(invitation_id)
	decline_btn.hide()
	accept_btn.hide()
	set_result("Invitation accepted.")
	emit_signal("add_notifications", -1)
	emit_signal("invitation_declined")

func _on_invite_decline():
	RestHandler.request_decline_invitation(invitation_id)
	decline_btn.hide()
	accept_btn.hide()
	set_result("Invitation declined.")
	emit_signal("add_notifications", -1)
	emit_signal("invitation_accepted")

func set_result(message : String):
	result_lbl.set_text(message)

func _on_invitation_accepted():
	emit_signal("set_to_load_next", true)
	queue_free()

func _on_invitation_declined():
	queue_free()

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

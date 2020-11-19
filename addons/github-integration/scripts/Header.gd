tool
extends Control

onready var discord : TextureButton = $datas/discord
onready var paypal : TextureButton = $datas/paypal
onready var github : TextureButton = $datas/github
onready var notifications_btn : TextureButton = $datas/notifications
onready var notifications_lbl : Label = $datas/notifications/VBoxContainer/NotificationsLbl

signal load_invitations(list)

var notifications : int = 0

func _ready():
	hide_notifications()
	_connect_signals()

func _connect_signals():
	discord.connect("pressed",self,"_join_discord")
	paypal.connect("pressed",self,"_support_paypal")
	github.connect("pressed",self,"_check_git")
	notifications_btn.connect("pressed", self, "_notifications_opened")

func set_darkmode(darkmode : bool):
	if darkmode:
		set_theme(load("res://addons/github-integration/resources/themes/GitHubTheme-Dark.tres"))
	else:
		set_theme(load("res://addons/github-integration/resources/themes/GitHubTheme.tres"))

func _join_discord():
	OS.shell_open("https://discord.gg/KnJGY9S")

func _support_paypal():
	OS.shell_open("https://paypal.me/NSantilio?locale.x=it_IT")

func _check_git():
	OS.shell_open("https://github.com/fenix-hub/godot-engine.github-integration")

func _notifications_opened():
	if get_parent().Notifications.visible :
		hide_notifications()
	else:
		if notifications > 0:
			set_notifications()

func _on_add_notifications(amount : int):
	notifications+=amount
	set_notifications()

func set_notifications():
	notifications_lbl.set_text(str(notifications))
	notifications_btn.set_tooltip("You have "+str(notifications)+" unread notifications")
	notifications_lbl.show() if notifications > 0 else hide_notifications()

func hide_notifications():
	notifications_lbl.hide()
	notifications_btn.set_tooltip("You have no unread notifications")





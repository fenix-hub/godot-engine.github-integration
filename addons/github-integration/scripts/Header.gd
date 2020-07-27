tool
extends Control

func _ready():
    pass # Replace with function body.


func set_darkmode(darkmode : bool):
    if darkmode:
        set_theme(load("res://addons/github-integration/resources/themes/GitHubTheme-Dark.tres"))
    else:
        set_theme(load("res://addons/github-integration/resources/themes/GitHubTheme.tres"))

tool
extends Control


onready var CloseBTN = $GistContainer/close
onready var List = $GistContainer/GistEditor/ListContainer/List
onready var ListBar = $GistContainer/GistEditor/ListContainer/ListBar
onready var Content = $GistContainer/GistEditor/ContentContainer/Content
onready var GistName = $GistContainer/gist_name
onready var GistDescription = $GistContainer/description/gist_description
onready var WrapButton = $GistContainer/GistEditor/ContentContainer/TopBar/WrapBtn
onready var MapButton = $GistContainer/GistEditor/ContentContainer/TopBar/MapBtn
onready var NewFileDialog = $NewFile
onready var Readonly = $GistContainer/GistEditor/ContentContainer/TopBar/Readonly

onready var edit_description = $GistContainer/description/edit_description

onready var addfile_btn = $GistContainer/GistEditor/ListContainer/ListBar/addfile
onready var deletefile_btn = $GistContainer/GistEditor/ListContainer/ListBar/deletefile
onready var commit_btn = $GistContainer/GistButtons/commit
onready var delete_btn = $GistContainer/GistButtons/delete

var request = HTTPRequest.new()
enum REQUESTS { REPOS = 0, GIST = 1, UP_REPOS = 2, UP_GISTS = 3, DELETE = 4, COMMIT = 5, BRANCHES = 6, CONTENTS = 7, TREES = 8, DELETE_RESOURCE = 9, END = -1 }
var requesting

var privacy : bool
var description : String
var gistid : String
var rootfile : String


enum GIST_MODE { CREATING = 0 , GETTING = 1 , EDITING = 2 }
var gist_mode

#signals
signal get_gist()
signal loaded_gist()
signal gist_committed()
signal gist_updated()
signal gist_deleted()

func _ready():
	add_child(request)
	connect_signals()
	Readonly.set_pressed(true)
	Content.set_readonly(true)
	hide()
	commit_btn.hide()



func set_darkmode(darkmode : bool):
	if darkmode:
		$BG.color = "#24292e"
		set_theme(load("res://addons/github-integration/resources/themes/GitHubTheme-Dark.tres"))
	else:
		$BG.color = "#f6f8fa"
		set_theme(load("res://addons/github-integration/resources/themes/GitHubTheme.tres"))

func connect_signals():
	request.connect("request_completed",self,"request_completed")
	CloseBTN.connect("pressed",self,"close_editor")
	List.connect("item_selected",self,"on_item_selected")
	WrapButton.connect("item_selected",self,"on_wrap_selected")
	MapButton.connect("item_selected",self,"_on_mapbutton_selected")
	
	addfile_btn.connect("pressed",self,"on_addfile")
	deletefile_btn.connect("pressed",self,"on_deletefile")
	commit_btn.connect("pressed",self,"on_commit")
	delete_btn.connect("pressed",self,"on_delete")
	
	NewFileDialog.connect("confirmed",self,"add_new_file")
	
	Content.connect("text_changed",self,"on_text_changed")
	
	Readonly.connect("toggled",self,"_on_Readonly_toggled")
	
	addfile_btn.set_button_icon(IconLoaderGithub.load_icon_from_name("file-gray"))
	deletefile_btn.set_button_icon(IconLoaderGithub.load_icon_from_name("file_broken"))
	
	RestHandler.connect("gist_created",self,"_on_gist_created")
	RestHandler.connect("gist_updated", self, "_on_gist_updated")
	RestHandler.connect("request_failed", self, "_on_request_failed")

func _on_request_failed(requesting : float , body : Dictionary):
	match requesting:
		RestHandler.REQUESTS.CREATE_GIST:
			get_parent().prind_debug_message(body)
		RestHandler.REQUESTS.UPDATE_GIST:
			get_parent().prind_debug_message(body)

func request_completed(result, response_code, headers, body ):
#	print(JSON.parse(body.get_string_from_utf8()).result)
	if result == 0:
		match requesting:
			REQUESTS.DELETE:
				if response_code == 204:
					get_parent().print_debug_message("gist deleted with success!")
					get_parent().UserPanel.request_gists(REQUESTS.GIST)
					emit_signal("gist_deleted")

func load_gist(gist_item : GistItem):
	var gist : Dictionary = gist_item._gist
	gistid = gist_item._id
	delete_btn.show()
	ListBar.hide()
	GistName.set_text(gist.owner.login+"/"+gist_item._name)
	if gist.description=="" or gist.description==" " or gist.description==null:
		GistDescription.set_text("<no description>")
		GistDescription.hide()
	else:
		GistDescription.set_text(gist.description)
		GistDescription.show()
	
	description = gist.description
	
	for file in range(gist_item._files_amount):
		
		var file_item = List.add_item(gist_item._files[file].name,IconLoaderGithub.load_icon_from_name("gists-back"))
		var this_index = List.get_item_count()-1
		List.set_item_metadata(this_index, gist_item._files[file])
		List.select(this_index)
		on_item_selected(this_index)
	
	Readonly.set_pressed(true)
	Content.set_readonly(true)
	show()
	get_parent().loading(false)

func on_item_selected(index : int):
	Content.clear_colors()
	var item_metadata = List.get_item_metadata(index)
	color_region(item_metadata.extension)
	Content.set_text(item_metadata.text)

func close_editor():
	List.clear()
	Content.set_text("")
	GistName.set_text("")
	GistDescription.set_text("")
	hide()
	get_parent().UserPanel.show()

func on_wrap_selected(index : int):
	Content.set_wrap_enabled(bool(index))

func _on_mapbutton_selected(index : int) -> void:
	Content.draw_minimap(bool(index))

func initialize_new_gist(privacy : bool , rootfile : String, description : String = "" , files : PoolStringArray = []):
	delete_btn.hide()
	GistDescription.show()
	gist_mode = GIST_MODE.CREATING
	commit_btn.set_button_icon(IconLoaderGithub.load_icon_from_name("add-gray"))
	self.privacy = privacy
	self.description = description
	self.rootfile = rootfile
	GistDescription.set_text(description)
	GistName.set_text("%s/%s" % [UserData.USER.login, rootfile])
	ListBar.show()
	commit_btn.show()
	commit_btn.set_text("Commit Gist")
	Content.set_readonly(true)
	Readonly.set_pressed(true)
	
	if files.size():
		for file in files:
			var gist_file = File.new()
			gist_file.open(file,File.READ)
			var filecontent = gist_file.get_as_text()
			gist_file.close()
			load_file(file.get_file(),filecontent)
	else:
		load_file(rootfile, "")
	show()

func on_addfile():
	NewFileDialog.popup()

func load_file(file_name : String, filecontent : String):
	var file_item = List.add_item(file_name,IconLoaderGithub.load_icon_from_name("gists-back"))
	var this_index = List.get_item_count()-1
	
	var metadata = { "text":filecontent, "name":file_name }
	
	List.set_item_metadata(this_index,metadata)
	List.select(this_index)
	on_item_selected(this_index)

func add_new_file():
	var item_filename = NewFileDialog.get_node("HBoxContainer2/filename").get_text()
	NewFileDialog.get_node("HBoxContainer2/filename").set_text("")
	var file_item = List.add_item(item_filename,IconLoaderGithub.load_icon_from_name("gists-back"))
	var this_index = List.get_item_count()-1
	
	var metadata = { "text":"", "name":item_filename }
	
	
	List.set_item_metadata(this_index,metadata)
	List.select(this_index)
	on_item_selected(this_index)

func on_deletefile():
	List.remove_item(List.get_selected_items()[0])
	Content.set_text("")

func on_text_changed():
	var _content : String = Content.get_text()
	var _filename : String = List.get_item_text(List.get_selected_items()[0]) if not List.get_selected_items().empty() else ""
	var metadata = { "text" : _content, "name" : _filename }
	if not List.get_selected_items().empty():
		List.set_item_metadata(List.get_selected_items()[0],metadata)

func _on_gist_created(body : Dictionary):
	GistName.set_text(UserData.USER.login+"/"+body.files.values()[0].filename)
	get_parent().print_debug_message("gist committed with success!")
	get_parent().UserPanel.request_gists(REQUESTS.GIST)

func _on_gist_updated(body : Dictionary):
	get_parent().print_debug_message("gist updated with success!")
	RestHandler.request_user_gists()

func _on_loaded_repositories() -> void:
	get_parent().loading(false)

func on_commit():
	get_parent().loading(true)
	var files : Dictionary
	
	for item in range(0,List.get_item_count()):
		if List.get_item_metadata(item).text != "":
			files[List.get_item_metadata(item).name] = {"content":List.get_item_metadata(item).text}
		else:
			files[List.get_item_metadata(item).name] = {"content":"null"}
	
	if gist_mode == GIST_MODE.CREATING:
		var body : Dictionary = {
			"description": description,
			"public": !privacy,
			"files": files,
		}
		RestHandler.request_gist_commit(JSON.print(body))
		get_parent().print_debug_message("committing new gist...")
	elif gist_mode == GIST_MODE.EDITING:
		var body : Dictionary = {
			"description": description,
			"files": files,
		}
		RestHandler.request_update_gist(gistid, JSON.print(body))
		get_parent().print_debug_message("updating this gist...")

func _on_Readonly_toggled(button_pressed):
	if gist_mode == GIST_MODE.CREATING:
		if button_pressed:
			Readonly.set_text("Read Only")
			Content.set_readonly(true)
		else:
			Readonly.set_text("Can Edit")
			Content.set_readonly(false)
	else:
		if button_pressed:
			Readonly.set_text("Read Only")
			Content.set_readonly(true)
			ListBar.hide()
			gist_mode = GIST_MODE.GETTING
			commit_btn.hide()
			edit_description.hide()
			if edit_description.get_node("gist_editdescription").get_text()!="":
				description = edit_description.get_node("gist_editdescription").get_text()
				GistDescription.set_text(description)
				GistDescription.show()
		else:
			Readonly.set_text("Can Edit")
			Content.set_readonly(false)
			ListBar.show()
			gist_mode = GIST_MODE.EDITING
			commit_btn.show()
			edit_description.show()
			GistDescription.hide()
			if GistDescription.get_text()!="<no description>":
				edit_description.get_node("gist_editdescription").set_text(GistDescription.get_text())

func on_delete():
	requesting = REQUESTS.DELETE
	request.request("https://api.github.com/gists/"+gistid,UserData.header,false,HTTPClient.METHOD_DELETE)
	get_parent().print_debug_message("deleting this gist...")
	yield(self,"gist_deleted")
	close_editor()

func color_region(filextension : String):
	match(filextension):
		"bbs":
			Content.add_color_region("[b]","[/b]",Color8(153,153,255,255),false)
			Content.add_color_region("[i]","[/i]",Color8(153,255,153,255),false)
			Content.add_color_region("[s]","[/s]",Color8(255,153,153,255),false)
			Content.add_color_region("[u]","[/u]",Color8(255,255,102,255),false)
			Content.add_color_region("[url","[/url]",Color8(153,204,255,255),false)
			Content.add_color_region("[code]","[/code]",Color8(192,192,192,255),false)
			Content.add_color_region("[img]","[/img]",Color8(255,204,153,255),false)
			Content.add_color_region("[center]","[/center]",Color8(175,238,238,255),false)
			Content.add_color_region("[right]","[/right]",Color8(135,206,235,255),false)
		"html":
			Content.add_color_region("<b>","</b>",Color8(153,153,255,255),false)
			Content.add_color_region("<i>","</i>",Color8(153,255,153,255),false)
			Content.add_color_region("<del>","</del>",Color8(255,153,153,255),false)
			Content.add_color_region("<ins>","</ins>",Color8(255,255,102,255),false)
			Content.add_color_region("<a","</a>",Color8(153,204,255,255),false)
			Content.add_color_region("<img","/>",Color8(255,204,153,255),true)
			Content.add_color_region("<pre>","</pre>",Color8(192,192,192,255),false)
			Content.add_color_region("<center>","</center>",Color8(175,238,238,255),false)
			Content.add_color_region("<right>","</right>",Color8(135,206,235,255),false)
		"md":
			Content.add_color_region("***","***",Color8(126,186,181,255),false)
			Content.add_color_region("**","**",Color8(153,153,255,255),false)
			Content.add_color_region("*","*",Color8(153,255,153,255),false)
			Content.add_color_region("+ ","",Color8(255,178,102,255),false)
			Content.add_color_region("- ","",Color8(255,178,102,255),false)
			Content.add_color_region("~~","~~",Color8(255,153,153,255),false)
			Content.add_color_region("__","__",Color8(255,255,102,255),false)
			Content.add_color_region("[",")",Color8(153,204,255,255),false)
			Content.add_color_region("`","`",Color8(192,192,192,255),false)
			Content.add_color_region('"*.','"',Color8(255,255,255,255),true)
			Content.add_color_region("# ","",Color8(105,105,105,255),true)
			Content.add_color_region("## ","",Color8(128,128,128,255),true)
			Content.add_color_region("### ","",Color8(169,169,169,255),true)
			Content.add_color_region("#### ","",Color8(192,192,192,255),true)
			Content.add_color_region("##### ","",Color8(211,211,211,255),true)
			Content.add_color_region("###### ","",Color8(255,255,255,255),true)
			Content.add_color_region("> ","",Color8(172,138,79,255),true)
		"cfg":
			Content.add_color_region("[","]",Color8(153,204,255,255),false)
			Content.add_color_region('"','"',Color8(255,255,102,255),false)
			Content.add_color_region(';','',Color8(128,128,128,255),true)
		"ini":
			Content.add_color_region("[","]",Color8(153,204,255,255),false)
			Content.add_color_region('"','"',Color8(255,255,102,255),false)
			Content.add_color_region(';','',Color8(128,128,128,255),true)
		_:
			pass


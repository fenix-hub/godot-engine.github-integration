tool
extends Node

var directory_name = "github_integration"
var plugin_path : String = ProjectSettings.globalize_path("user://").replace("app_userdata/"+ProjectSettings.get_setting('application/config/name')+"/",directory_name)+"/"

var setting_file : String = "settings.cfg"

var debug : bool = true
var auto_log : bool = false
var darkmode : bool = false
var auto_update_notifications : bool = true
var auto_update_timer : float = 300
var owner_affiliations : Array = ["OWNER","COLLABORATOR","ORGANIZATION_MEMBER"]

var _loaded : bool = false

func _check_plugin_path():
	var dir = Directory.new()
	if not dir.dir_exists(plugin_path):
		dir.make_dir(plugin_path)
		if debug:
			printerr("[GitHub Integration] >> ","made custom directory in user folder, it is placed at ", plugin_path)

func _ready():
	_check_plugin_path()
	var config_file : ConfigFile = ConfigFile.new()
	var err = config_file.load(plugin_path+setting_file)
	if err == 0:
		debug = config_file.get_value("settings","debug", debug)
		auto_log = config_file.get_value("settings","auto_log", auto_log)
		darkmode = config_file.get_value("settings","darkmode", darkmode)
		auto_update_notifications = config_file.get_value("settings","auto_update_notifications", auto_update_notifications)
		auto_update_timer = config_file.get_value("settings","auto_update_timer",auto_update_timer)
		owner_affiliations = config_file.get_value("settings", "owner_affiliations", owner_affiliations)
	else:
		config_file.save(plugin_path+setting_file)
		config_file.set_value("settings","debug",debug)
		config_file.set_value("settings","auto_log",auto_log)
		config_file.set_value("settings","darkmode",darkmode)
		config_file.set_value("settings","auto_update_notifications", auto_update_notifications)
		config_file.set_value("settings","auto_update_timer",auto_update_timer)
		config_file.set_value("settings","owner_affiliations",owner_affiliations)
		config_file.save(plugin_path+setting_file)
	_loaded = true

func set_debug(d : bool):
	debug = d
	save_setting("debug", debug)

func set_auto_log(a : bool):
	auto_log = a
	save_setting("auto_log", auto_log)

func set_darkmode(d : bool):
	darkmode = d
	save_setting("darkmode", darkmode)

func set_auto_update_notifications(enabled : bool):
	auto_update_notifications = enabled
	save_setting("auto_update_notifications", enabled)

func set_auto_update_timer(timer : float):
	auto_update_timer = timer
	save_setting("auto_update_timer", timer)

func set_owner_affiliations(affiliations : Array):
	owner_affiliations = affiliations
	save_setting("owner_affiliations", owner_affiliations)

func save_setting(key : String, value):
	_check_plugin_path()
	var file : ConfigFile = ConfigFile.new()
	var err = file.load(plugin_path+setting_file)
	if err == OK:
		file.set_value("settings",key,value)
	file.save(plugin_path+setting_file)

func get_setting(key : String, default_value = ""):
	_check_plugin_path()
	var file : ConfigFile = ConfigFile.new()
	var err = file.load(plugin_path+setting_file)
	if err == OK:
		if file.has_section_key("settings","key"):
			return file.get_value("settings","key")
		else:
			print("setting '%s' not found, now created" % key)
			file.set_value("settings", key, default_value)

func reset_plugin():
	delete_all_files(plugin_path)
	print("[Github Integration] github_integration folder completely removed.")

func delete_all_files(path : String):
	var directories = []
	var dir : Directory = Directory.new()
	dir.open(path)
	dir.list_dir_begin(true,false)
	var file = dir.get_next()
	while (file != ""):
		if dir.current_is_dir():
			var directorypath = dir.get_current_dir()+"/"+file
			directories.append(directorypath)
		else:
			var filepath = dir.get_current_dir()+"/"+file
			dir.remove(filepath)
		
		file = dir.get_next()
	
	dir.list_dir_end()
	
	for directory in directories:
		delete_all_files(directory)
	dir.remove(path)

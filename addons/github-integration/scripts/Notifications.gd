tool
extends Control

var invitation_item_scene : PackedScene = preload("res://addons/github-integration/scenes/InvitationItem.tscn")

onready var timer : Timer = $Timer
onready var tabs : VBoxContainer = $NotificationsContainer/NotificationsTabs/Tabs
onready var notification_tree : Tree = $NotificationsContainer/NotificationsTabs/NotificationsTree
onready var invitations_list_box : VBoxContainer = tabs.get_node("Invitations")
onready var settings_list_box : VBoxContainer = tabs.get_node("Settings")
onready var auto_update_notifications_chk : CheckButton = $NotificationsContainer/NotificationsTabs/Tabs/Settings/Notifications/AutoUpdateNotificationsChk
onready var auto_update_notifications_amount : LineEdit = $NotificationsContainer/NotificationsTabs/Tabs/Settings/Notifications/AutoUpdateTimer/Amount
onready var debug_messages_chk : CheckButton = $NotificationsContainer/NotificationsTabs/Tabs/Settings/Plugin/DebugMessagesChk
onready var auto_login_chk : CheckButton = $NotificationsContainer/NotificationsTabs/Tabs/Settings/Plugin/AutoLoginChk
onready var darkmode_chck : CheckButton = $NotificationsContainer/NotificationsTabs/Tabs/Settings/Plugin/DarkmodeChk
onready var owner_check : CheckBox = $NotificationsContainer/NotificationsTabs/Tabs/Settings/Repositories/OwnerAffiliations/Owner
onready var collaborator_check : CheckBox = $NotificationsContainer/NotificationsTabs/Tabs/Settings/Repositories/OwnerAffiliations/Collaborator
onready var organization_member_check : CheckBox = $NotificationsContainer/NotificationsTabs/Tabs/Settings/Repositories/OwnerAffiliations/OrganizationMember


signal add_notifications(amount)

var to_load_next : bool = false
var notifications_tabs : Array = ["Invitations", "Settings"]

func _ready():
    if PluginSettings._loaded : pass
    else: yield(PluginSettings,"ready")
    load_settings()
    _connect_signals()
    load_notification_tabs()
    notification_tree.get_root().get_children().select(0)
    set_invitations_amount(0)

func _connect_signals() -> void:
    timer.connect("timeout", self, "_on_timeout")
    notification_tree.connect("item_selected", self, "_on_item_selected")
    RestHandler.connect("notification_request_failed", self, "_on_notification_request_failed")
    RestHandler.connect("invitations_list_requested", self, "_on_invitations_list_requested")
    auto_update_notifications_chk.connect("toggled", self, "_on_auto_update_toggled")
    auto_update_notifications_amount.connect("text_entered", self, "_on_auto_update_amount_entered")
    debug_messages_chk.connect("toggled", self, "_on_debug_toggled")
    auto_login_chk.connect("toggled", self, "_on_autologin_toggled")
    darkmode_chck.connect("toggled", self, "_on_darkmode_toggled")
    $NotificationsContainer/NotificationsTabs/Tabs/Settings/ResetPluginBtn.connect("pressed", self, "_on_reset_plugin_pressed")
    $ResetPluginDialog.connect("confirmed", self, "_on_reset_confirmed")
    owner_check.connect("toggled", self, "_on_owner_check_pressed")
    collaborator_check.connect("toggled", self, "_on_collaborator_check_pressed")
    organization_member_check.connect("toggled", self, "_on_organization_member_check_pressed")

func load_settings():
    var auto_update_notifications : bool = PluginSettings.auto_update_notifications
    var auto_update_timer : float = PluginSettings.auto_update_timer
    var darkmode : bool = PluginSettings.darkmode
    set_auto_update_timer(auto_update_timer)
    set_auto_update(auto_update_notifications)
    auto_update_notifications_chk.set_pressed(auto_update_notifications)
    auto_update_notifications_amount.set_text(str(auto_update_timer/60))
    debug_messages_chk.set_pressed(PluginSettings.debug)
    auto_login_chk.set_pressed(PluginSettings.auto_log)
    darkmode_chck.set_pressed(darkmode)
    var owner_affiliations : Array = PluginSettings.owner_affiliations
    load_owner_affiliations(owner_affiliations)

func load_owner_affiliations(affiliations : Array):
    owner_check.set_pressed("OWNER" in affiliations)
    collaborator_check.set_pressed("COLLABORATOR" in affiliations)
    organization_member_check.set_pressed("ORGANIZATION_MEMBER" in affiliations)

func _on_notification_request_failed(requesting : int, error_body : Dictionary):
    match requesting:
        RestHandler.REQUESTS.INVITATIONS_LIST:
            get_parent().print_debug_message("ERROR: "+error_body.message, 1)

func hide_notification_tab(tab : TreeItem) -> TreeItem:
    if tab.get_text(0) != "Settings": tab.hide()
    return tab.get_next()

func load_notification_tabs() -> void:
    var root : TreeItem = notification_tree.create_item()
    for tab in notifications_tabs:
        var invitations_item : TreeItem = notification_tree.create_item(root)
        invitations_item.set_text(0, tab)

func hide_notification_tabs():
    var next_item : TreeItem = hide_notification_tab(notification_tree.get_root().get_children())
    while next_item!=null:
        next_item = hide_notification_tab(next_item)

func set_darkmode(darkmode : bool) -> void:
    if darkmode:
        $BG.color = "#24292e"
        set_theme(load("res://addons/github-integration/resources/themes/GitHubTheme-Dark.tres"))
    else:
        $BG.color = "#f6f8fa"
        set_theme(load("res://addons/github-integration/resources/themes/GitHubTheme.tres"))

func _open_notifications():
    set_visible(not visible)
    get_parent().UserPanel.load_panel() if (not visible and to_load_next) else null

func _on_item_selected():
    var item : TreeItem = notification_tree.get_selected()
    for tab in tabs.get_children(): tab.hide() if tab is VBoxContainer else null
    tabs.get_node(item.get_text(0)).show()

func _on_timeout():
    request_notifications()

func request_notifications() -> void:
    if not PluginSettings.auto_update_notifications: return
    if UserData.USER == {} : return
    get_parent().print_debug_message("loading notifications, please wait...")
    emit_signal("add_notifications",-get_parent().Header.notifications)
    RestHandler.request_invitations_list()

func _on_invitations_list_requested(invitations_list : Array) -> void:
    if invitations_list.size():
        emit_signal("add_notifications", invitations_list.size())
        _on_load_invitations_list(invitations_list)

var invitations : int

func _on_load_invitations_list(invitations_list : Array) -> void:
    clear_invitations_list()
    invitations = invitations_list.size()
    for invitation in invitations_list:
        var invitation_item : InvitationItem = invitation_item_scene.instance()
        invitations_list_box.add_child(invitation_item)
        invitation_item.load_invitation(invitation)
        invitation_item.connect("set_to_load_next", self, "set_to_load_next")
        invitation_item.connect("add_notifications", get_parent().Header, "_on_add_notifications")
        invitation_item.connect("invitation_accepted", self, "_on_invitation_accepted")
        invitation_item.connect("invitation_declined", self, "_on_invitation_declined")
    set_invitations_amount(invitations_list.size())

func _on_auto_update_toggled(toggled : bool):
    set_auto_update(toggled)
    get_parent().print_debug_message("auto update for notifications: %s" % ["enabled" if toggled else "disabled"])

func _on_auto_update_amount_entered(amount_txt : String):
    if amount_txt.is_valid_float() or amount_txt.is_valid_integer():
        set_auto_update_timer(float(amount_txt)*60)
        get_parent().print_debug_message("auto update timer for notifications set to %s minute(s)" % amount_txt)

# If the "debug" button is toggled
func _on_debug_toggled(button_pressed : bool) -> void:
    PluginSettings.set_debug(button_pressed)
    get_parent().print_debug_message("Debug messages in output console: %s" % button_pressed)

# If the "auto login" button is toggled
func _on_autologin_toggled(button_pressed : bool) -> void:
    PluginSettings.set_auto_log(button_pressed)
    get_parent().print_debug_message("Auto Login at plugin startup: %s" % button_pressed)

func _on_darkmode_toggled(toggled : bool):
    get_parent().print_debug_message("Darkmode set to %s" % toggled)
    get_parent().set_darkmode(toggled)

func set_auto_update_timer(amount : float):
    timer.set_wait_time(amount)
    PluginSettings.set_auto_update_timer(amount)

func set_auto_update(enabled : bool):
    timer.start() if enabled else timer.stop()
    PluginSettings.set_auto_update_notifications(enabled)

func clear_invitations_list():
    invitations = 0
    for invitation in invitations_list_box.get_children(): invitation.free() if not invitation is Label else null
    set_invitations_amount(0)

func set_invitations_amount(amount : int):
    tabs.get_node("Invitations/Label").set_text("There are %s invitations received"%amount)

func set_to_load_next(to_load : bool):
    to_load_next = to_load

func _on_invitation_accepted():
    invitations-=1
    set_invitations_amount(invitations)

func _on_invitation_declined():
    invitations-=1
    set_invitations_amount(invitations)

func _on_reset_plugin_pressed():
    $ResetPluginDialog.popup()

func _clear():
    emit_signal("add_notifications",-get_parent().Header.notifications)
    clear_invitations_list()

func _on_reset_confirmed():
    _clear()
    hide()
    get_parent().logout()
    get_parent().SignIn.delete_user()
    PluginSettings.reset_plugin()

func _on_owner_check_pressed(toggled : bool):
    if toggled: 
        if not "OWNER" in PluginSettings.owner_affiliations: 
            PluginSettings.owner_affiliations.append("OWNER")
    else: 
        if "OWNER" in PluginSettings.owner_affiliations: 
            PluginSettings.owner_affiliations.erase("OWNER")
    PluginSettings.set_owner_affiliations(PluginSettings.owner_affiliations)
    get_parent().print_debug_message("repositories setting '%s': %s"%["OWNER",toggled])

func _on_collaborator_check_pressed(toggled : bool):
    if toggled: 
        if not ("COLLABORATOR" in PluginSettings.owner_affiliations): 
            PluginSettings.owner_affiliations.append("COLLABORATOR")
    else: 
        if "COLLABORATOR" in PluginSettings.owner_affiliations: 
            PluginSettings.owner_affiliations.erase("COLLABORATOR")
    PluginSettings.set_owner_affiliations(PluginSettings.owner_affiliations)
    get_parent().print_debug_message("repositories setting '%s': %s"%["COLLABORATOR",toggled])

func _on_organization_member_check_pressed(toggled : bool):
    if toggled: 
        if not "ORGANIZATION_MEMBER" in PluginSettings.owner_affiliations: 
            PluginSettings.owner_affiliations.append("ORGANIZATION_MEMBER")
    else: 
        if "ORGANIZATION_MEMBER" in PluginSettings.owner_affiliations: 
            PluginSettings.owner_affiliations.erase("ORGANIZATION_MEMBER")
    PluginSettings.set_owner_affiliations(PluginSettings.owner_affiliations)
    get_parent().print_debug_message("repositories setting '%s': %s"%["ORGANIZATION_MEMBER",toggled])

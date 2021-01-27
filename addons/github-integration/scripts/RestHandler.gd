tool
extends Node

signal _check_connection(connection)
signal request_failed(request_code, error_body)
signal notification_request_failed(request_code, error_body)
signal user_requested(user)
signal user_avatar_requested(avatar)
signal contributor_avatar_requested(avatar)
signal user_repositories_requested(repositories)
signal user_repository_requested(repository)
signal user_gists_requested(gists)
signal gist_created(gist)
signal gist_updated(gist)
signal branch_contents_requested(branch_contents)
signal gitignore_requested(gitignore)
signal file_content_requested(file_content)
signal pull_branch_requested()
signal collaborator_requested()
signal resource_delete_requested()
signal repository_delete_requested()
signal new_branch_requested()
signal invitations_list_requested(list)
signal invitation_accepted()
signal invitation_declined()

var requesting : int = -1
var notifications_requesting : int = -1

var repositories_limit : int = 100
var gists_limit : int = 100
var owner_affiliations : String

var checking_connection : bool = false
var downloading_file : bool = false

onready var client : HTTPRequest = $Client
onready var notifications_client : HTTPRequest = $NotificationsClient
var loading : Control
var session : HTTPClient = HTTPClient.new()
var graphql_endpoint : String = "https://api.github.com/graphql"
var graphql_queries : Dictionary = {
    'repositories':'{user(login: "%s"){repositories(ownerAffiliations:%s, first:%d, orderBy: {field: NAME, direction: ASC}){ nodes { diskUsage name owner { login } description url isFork isPrivate forkCount stargazerCount isInOrganization collaborators(affiliation: DIRECT, first: 100) { nodes {login name avatarUrl} } mentionableUsers(first: 100){ nodes{ login name avatarUrl } } defaultBranchRef { name } refs(refPrefix: "refs/heads/", first: 100){ nodes{ name target { ... on Commit { oid tree { oid } zipballUrl tarballUrl } } } } } } %s } }',
    'repository':'{%s(login: "%s"){repository(name:"%s"){diskUsage name owner { login } description url isFork isPrivate forkCount stargazerCount isInOrganization collaborators(affiliation: DIRECT, first: 100) { nodes {login name avatarUrl} } mentionableUsers(first: 100){ nodes{ login name avatarUrl } } defaultBranchRef { name } refs(refPrefix: "refs/heads/", first: 100){ nodes{ name target { ... on Commit { oid tree { oid } zipballUrl tarballUrl }}}}}}}',
    'gists':'{ user(login: "%s") { gists(first: %s, orderBy: {field: PUSHED_AT, direction: DESC}, privacy: ALL) { nodes { owner { login } id description resourcePath name stargazerCount isPublic isFork files { encodedName encoding extension name size text } } } } }',
    'organizations_repositories':'organizations(first:10){nodes{repositories(first:100){nodes{diskUsage name owner { login } description url isFork isPrivate forkCount stargazerCount isInOrganization collaborators(affiliation: DIRECT, first: 100) { nodes {login name avatarUrl} } mentionableUsers(first: 100){ nodes{ login name avatarUrl } } defaultBranchRef { name } refs(refPrefix: "refs/heads/", first: 100){ nodes{ name target { ... on Commit { oid tree { oid } zipballUrl tarballUrl } } } } }}}}'
}
var header : PoolStringArray = ["Authorization: token "]
var api_endpoints : Dictionary = {
    "github":"https://github.com/",
    "user":"https://api.github.com/user",
    "gist":"https://api.github.com/gists",
    "repos":"https://api.github.com/repos",
    "invitations":"https://api.github.com/user/repository_invitations"
}
enum REQUESTS {
    USER,
    USER_AVATAR,
    CONTRIBUTOR_AVATAR,
    USER_REPOSITORIES,
    USER_REPOSITORY,
    USER_GISTS,
    CREATE_GIST,
    UPDATE_GIST,
    BRANCH_CONTENTS,
    FILE_CONTENT,
    GITIGNORE,
    PULL_BRANCH,
    INVITE_COLLABORATOR,
    DELETE_RESOURCE,
    DELETE_REPOSITORY,
    NEW_BRANCH,
    INVITATIONS_LIST,
    ACCEPT_INVITATION,
    DECLINE_INVITATION
}

# Called when the node enters the scene tree for the first time.
func _ready():
    client.connect("request_completed",self,"_on_request_completed")
    notifications_client.connect("request_completed",self,"_on_notification_request_completed")

func load_default_variables():
    pass

func check_connection() -> void:
    checking_connection = true
    var connection : int = session.connect_to_host("www.githubstatus.com")
    assert(connection == OK) # Make sure connection was OK.
    set_process(true)
    if PluginSettings.debug:
        print("[GitHub Integration] Connecting to API, please wait...")

func _process(delta):
    process_check_connection()
    process_download_file()

func process_check_connection():
    if not checking_connection:
        return
    if session.get_status() == HTTPClient.STATUS_CONNECTING or session.get_status() == HTTPClient.STATUS_RESOLVING:
        session.poll()
    else:
        if session.get_status() == HTTPClient.STATUS_CONNECTED:
            if PluginSettings.debug:
                print("[GitHub Integration] Connection to API successful")
            emit_signal("_check_connection",true)
        else:
            if PluginSettings.debug:
                printerr("[GitHub Integration] Connection to API unsuccessful, exited with error %s, staus: %s" % 
            [session.get_response_code(), session.get_status()])
            emit_signal("_check_connection",false)
        checking_connection = false
        set_process(false)

func process_download_file():
    if downloading_file:
        loading.show_number(client.get_downloaded_bytes()*0.001, disk_usage, "KB")

# Print the GraphQL query from a String to a JSON/String for GraphQL endpoint
func print_query(query : String) -> String:
    return JSON.print( { "query":query } )

# Parse the result body to a Dictionary with the requested parameter as the root
func parse_body_data(body : PoolByteArray) -> Dictionary:
    return JSON.parse(body.get_string_from_utf8()).result.data

func parse_body(body : PoolByteArray) -> Dictionary:
    return JSON.parse(body.get_string_from_utf8()).result

func _on_notification_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray) -> void:
    if result == 0:
        match response_code:
            200:
                match notifications_requesting:
                    REQUESTS.INVITATIONS_LIST: emit_signal("invitations_list_requested", parse_body(body))
            204:
                match notifications_requesting:
                    REQUESTS.ACCEPT_INVITATION: emit_signal("invitation_accepted")
                    REQUESTS.DECLINE_INVITATION: emit_signal("invitation_declined")
            304:
                emit_signal("notification_request_failed", notifications_requesting, parse_body(body))
            400:
                emit_signal("notification_request_failed", notifications_requesting, parse_body(body))
            401:
                emit_signal("notification_request_failed", notifications_requesting, parse_body(body))
            403:
                emit_signal("notification_request_failed", notifications_requesting, parse_body(body))
            404:
                emit_signal("notification_request_failed", notifications_requesting, parse_body(body))
            422:
                emit_signal("notification_request_failed", notifications_requesting, parse_body(body))

func _on_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray) -> void:
#	print(JSON.parse(body.get_string_from_utf8()).result)
    if result == 0:
        match response_code:
            200:
                match requesting:
                    REQUESTS.USER: emit_signal("user_requested", parse_body(body))
                    REQUESTS.USER_AVATAR:
                        emit_signal("user_avatar_requested", body)
#						set_process(false)
#						client.set_download_file("")
                    REQUESTS.CONTRIBUTOR_AVATAR: 
                        emit_signal("contributor_avatar_requested", body)
                        temp_contributor.contributor_avatar_requested(body)
                    REQUESTS.USER_REPOSITORIES: emit_signal("user_repositories_requested", parse_body_data(body))
                    REQUESTS.USER_REPOSITORY: emit_signal("user_repository_requested", parse_body_data(body))
                    REQUESTS.USER_GISTS: emit_signal("user_gists_requested", parse_body_data(body))
                    REQUESTS.UPDATE_GIST: emit_signal("gist_updated", parse_body(body))
                    REQUESTS.BRANCH_CONTENTS: emit_signal("branch_contents_requested", parse_body(body))
                    REQUESTS.GITIGNORE: emit_signal("gitignore_requested", parse_body(body))
                    REQUESTS.FILE_CONTENT: emit_signal("file_content_requested", parse_body(body))
                    REQUESTS.PULL_BRANCH:
                        set_process(false)
                        client.set_download_file("")
                        emit_signal("pull_branch_requested")
                    REQUESTS.DELETE_RESOURCE: emit_signal("resource_delete_requested")
            201:
                match requesting:
                    REQUESTS.CREATE_GIST: emit_signal("gist_created", parse_body(body))
                    REQUESTS.INVITE_COLLABORATOR: emit_signal("collaborator_requested")
                    REQUESTS.NEW_BRANCH: emit_signal("new_branch_requested")
            204:
                match requesting:
                    REQUESTS.DELETE_REPOSITORY: emit_signal("repository_delete_requested")
                    _: emit_signal("request_failed", requesting, parse_body(body))
            400:
                emit_signal("request_failed", requesting, parse_body(body))
            401:
                emit_signal("request_failed", requesting, parse_body(body))
            403:
                emit_signal("request_failed", requesting, parse_body(body))
            422:
                emit_signal("request_failed", requesting, parse_body(body))
    downloading_file = false
    loading.hide_number()

# ------------------------- REQUESTS -----------------------
func request_user(token : String) -> void:
    requesting = REQUESTS.USER
    var temp_header = [header[0] + token]
    client.request(api_endpoints.user, temp_header, false, HTTPClient.METHOD_GET)

func request_user_avatar(avatar_url : String) -> void:
#	client.set_download_file(UserData.directory+UserData.avatar_name)
    requesting = REQUESTS.USER_AVATAR
#	downloading_file = true
    client.request(avatar_url)
#	set_process(true)

var temp_contributor : ContributorClass

func request_contributor_avatar(avatar_url : String, contributor_class : ContributorClass) -> void:
    requesting = REQUESTS.CONTRIBUTOR_AVATAR
    temp_contributor = contributor_class
    client.request(avatar_url)

func request_user_repositories() -> void:
    requesting = REQUESTS.USER_REPOSITORIES
    var owner_affiliations : Array = PluginSettings.owner_affiliations.duplicate(true)
    var is_org_member : bool = false
    if owner_affiliations.has("ORGANIZATION_MEMBER"): 
        owner_affiliations.erase("ORGANIZATION_MEMBER")
        is_org_member = true
    var query : String = graphql_queries.repositories % [UserData.USER.login, owner_affiliations, repositories_limit, graphql_queries.organizations_repositories if is_org_member else ""]
    client.request(graphql_endpoint, UserData.header, true, HTTPClient.METHOD_POST, print_query(query))

func request_user_repository(repository_affiliation : String, repository_owner : String, repository_name : String) -> void:
    requesting = REQUESTS.USER_REPOSITORY
    var query : String = graphql_queries.repository % [repository_affiliation, repository_owner, repository_name]
    client.request(graphql_endpoint, UserData.header, true, HTTPClient.METHOD_POST, print_query(query))

func request_user_gists() -> void:
    requesting = REQUESTS.USER_GISTS
    var query : String = graphql_queries.gists % [UserData.USER.login, gists_limit]
    client.request(graphql_endpoint, UserData.header, true, HTTPClient.METHOD_POST, print_query(query))

func request_commit_gist(body : String) -> void:
    requesting = REQUESTS.CREATE_GIST
    client.request(api_endpoints.gist, UserData.header, true, HTTPClient.METHOD_POST, body)

func request_update_gist(gistid : String, body : String) -> void:
    requesting = REQUESTS.UPDATE_GIST
    client.request(api_endpoints.gist+"/"+gistid,UserData.header,true,HTTPClient.METHOD_PATCH,body)

func request_branch_contents(repository_name : String, repository_owner : String, branch : Dictionary) ->  void:
    requesting = REQUESTS.BRANCH_CONTENTS
    client.request(api_endpoints.repos+"/"+repository_owner+"/"+repository_name+"/git/trees/"+branch.target.tree.oid+"?recursive=1",UserData.header,true,HTTPClient.METHOD_GET)

func request_file_content(repository_owner : String, repository_name : String, file_path : String, branch_name : String) -> void:
    requesting = REQUESTS.FILE_CONTENT
    client.request(api_endpoints.repos+"/"+repository_owner+"/"+repository_name+"/contents/"+file_path+"?ref="+branch_name,UserData.header,false,HTTPClient.METHOD_GET)

func request_gitignore(repository_owner : String, repository_name : String, branch_name : String) -> void:
    requesting = REQUESTS.GITIGNORE
    client.request(api_endpoints.repos+"/"+repository_owner+"/"+repository_name+"/contents/.gitignore?ref="+branch_name,UserData.header,false,HTTPClient.METHOD_GET)

var disk_usage : float
func request_pull_branch(ball_path : String, typeball_url: String, repo_disk_usage : float) -> void:
    client.set_download_file(ball_path)
    requesting = REQUESTS.PULL_BRANCH
    downloading_file = true
    disk_usage = repo_disk_usage
    client.request(typeball_url, UserData.header, true, HTTPClient.METHOD_GET)
    set_process(true)

func request_collaborator(repository_owner : String, repository_name : String, collaborator_name : String, body : Dictionary) -> void:
    requesting = REQUESTS.INVITE_COLLABORATOR
    client.request(api_endpoints.repos+"/"+repository_owner+"/"+repository_name+"/collaborators/"+collaborator_name, UserData.header, true, HTTPClient.METHOD_PUT, JSON.print(body))

func request_delete_resource(repository_owner : String, repository_name : String, path : String, body : Dictionary) -> void:
    requesting = REQUESTS.DELETE_RESOURCE
    client.request(api_endpoints.repos+"/"+repository_owner+"/"+repository_name+"/contents/"+path, UserData.header, true, HTTPClient.METHOD_DELETE,JSON.print(body))

func request_delete_repository(repository_owner : String, repository_name : String) -> void:
    requesting = REQUESTS.DELETE_REPOSITORY
    client.request(api_endpoints.repos+"/"+repository_owner+"/"+repository_name, UserData.header, true, HTTPClient.METHOD_DELETE)

func request_create_new_branch(repository_owner : String, repository_name : String, body : Dictionary) -> void:
    requesting = REQUESTS.NEW_BRANCH
    client.request(api_endpoints.repos+"/"+repository_owner+"/"+repository_name+"/git/refs",UserData.header, true, HTTPClient.METHOD_POST, JSON.print(body))

func request_invitations_list():
    notifications_requesting = REQUESTS.INVITATIONS_LIST
    notifications_client.request(api_endpoints.invitations, UserData.header)

func request_accept_invitation(invitation_id : int):
    notifications_requesting = REQUESTS.ACCEPT_INVITATION
    notifications_client.request(api_endpoints.invitations+"/"+str(invitation_id), UserData.header, true, HTTPClient.METHOD_PATCH)

func request_decline_invitation(invitation_id : int):
    notifications_requesting = REQUESTS.DECLINE_INVITATION
    notifications_client.request(api_endpoints.invitations+"/"+str(invitation_id), UserData.header, true, HTTPClient.METHOD_DELETE)

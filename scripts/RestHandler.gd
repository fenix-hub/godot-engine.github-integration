tool
extends Node

signal _check_connection(connection)
signal request_failed(request_code, error_body)
signal user_requested(user)
signal user_avatar_requested(avatar)
signal contributor_avatar_requested(avatar)
signal user_repositories_requested(repositories)
signal user_gists_requested(gists)
signal gist_created(gist)
signal gist_updated(gist)

var session : HTTPClient = HTTPClient.new()
var client : HTTPRequest = HTTPRequest.new()
var graphql_endpoint : String = "https://api.github.com/graphql"
var graphql_queries : Dictionary = {
	'repositories':'{user(login: "%s"){repositories(ownerAffiliations:[OWNER,COLLABORATOR,ORGANIZATION_MEMBER], first:%s, orderBy: {field: NAME, direction: ASC}){ nodes { name owner { login } description url isFork isPrivate forkCount stargazerCount isInOrganization collaborators(affiliation: DIRECT, first: 100) { nodes {login name avatarUrl} } mentionableUsers(first: 100){ nodes{ login name avatarUrl } } defaultBranchRef { name } refs(refPrefix: "refs/heads/", first: 100){ nodes{ name } } } } } }',
	'gists':'{ user(login: "%s") { gists(first: %s, orderBy: {field: PUSHED_AT, direction: DESC}, privacy: ALL) { nodes { owner { login } id description resourcePath name stargazerCount isPublic isFork files { encodedName encoding extension name size text } } } } }',
}
var header : PoolStringArray = ["Authorization: token "]
var api_endpoints : Dictionary = {
	"user":"https://api.github.com/user",
	"gist":"https://api.github.com/gists",
}
enum REQUESTS {
	USER,
	USER_AVATAR,
	CONTRIBUTOR_AVATAR,
	USER_REPOSITORIES,
	USER_GISTS,
	CREATE_GIST,
	UPDATE_GIST
}
var requesting : int = -1

var repositories_limit : int = 100
var gists_limit : int = 100

# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(client)
	client.connect("request_completed",self,"_on_request_completed")

func check_connection() -> void:
	var connection : int = session.connect_to_host("www.githubstatus.com")
	assert(connection == OK) # Make sure connection was OK.
	set_process(true)
	if PluginSettings.debug:
		print("[GitHub Integration] Connecting to API, please wait...")

func _process(delta):
	# Wait until resolved and connected.
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
		set_process(false)

# Print the GraphQL query from a String to a JSON/String for GraphQL endpoint
func print_query(query : String) -> String:
	return JSON.print( { "query":query } )

# Parse the result body to a Dictionary with the requested parameter as the root
func parse_body_data(body : PoolByteArray) -> Dictionary:
	return JSON.parse(body.get_string_from_utf8()).result.data

func parse_body(body : PoolByteArray) -> Dictionary:
	return JSON.parse(body.get_string_from_utf8()).result


func _on_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray) -> void:
	if result == 0:
		match response_code:
			200:
				match requesting:
					REQUESTS.USER: emit_signal("user_requested", parse_body(body))
					REQUESTS.USER_AVATAR:
						emit_signal("user_avatar_requested", body)
						client.set_download_file("")
					REQUESTS.CONTRIBUTOR_AVATAR: 
						emit_signal("contributor_avatar_requested", body)
						temp_contributor.contributor_avatar_requested(body)
					REQUESTS.USER_REPOSITORIES: emit_signal("user_repositories_requested", parse_body_data(body))
					REQUESTS.USER_GISTS: emit_signal("user_gists_requested", parse_body_data(body))
					REQUESTS.UPDATE_GIST: emit_signal("gist_updated", parse_body(body))
			201:
				match requesting:
					REQUESTS.CREATE_GIST: emit_signal("gist_created", parse_body(body))
			400:
				emit_signal("request_failed", requesting, parse_body(body))
			401:
				emit_signal("request_failed", requesting, parse_body(body))


# ------------------------- REQUESTS -----------------------
func request_user(token : String) -> void:
	requesting = REQUESTS.USER
	var temp_header = [header[0] + token]
	client.request(api_endpoints.user, temp_header, false, HTTPClient.METHOD_GET)

func request_user_avatar(avatar_url : String) -> void:
	client.set_download_file(UserData.directory+UserData.avatar_name)
	requesting = REQUESTS.USER_AVATAR
	client.request(avatar_url)

var temp_contributor : ContributorClass

func request_contributor_avatar(avatar_url : String, contributor_class : ContributorClass) -> void:
	requesting = REQUESTS.CONTRIBUTOR_AVATAR
	temp_contributor = contributor_class
	client.request(avatar_url)

func request_user_repositories() -> void:
	requesting = REQUESTS.USER_REPOSITORIES
	var query : String = graphql_queries.repositories % [UserData.USER.login, repositories_limit]
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

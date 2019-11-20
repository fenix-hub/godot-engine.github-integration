**version 0.1.5**  
*added*  
+ Light code clean  
+ Some Bugfix  
+ Plugin output for debug of some of the operations  
+ Automatic Filling of sign in fields  
+ Multiple files commit and changes commit  
+ Every text and image file format supported   
+ Filtering in committing  
+ Autoload branches content  

*removed*  
+ Single file commit  
+ Only text file commit  

----------------------

**version 0.2.5**  
*added*  
+ Code clean  
+ Chose branch to commit  
+ Delete resource selected in repository  
+ Filters: Exceptions, Only, Start from  

----------------------

**version 0.2.7**  
*added*  
+ Code clean  
+ Fix some little animations
+ New commit method: tree created from blobs, creates a single commit with more files

*removed*
+ Old commit method

----------------------

**version 0.2.9**  
*added*  
+ Code clean  
+ Bugfix with commits
+ A marker next to "Sign-in" buttons appears if a logfile is found

----------------------

**version 0.3.1**  
*added*  
+ Several bugfixes 

--------------------

**version 0.3.2**  
*added*
+ New folder organization (whole plugin in *addon* folder)
+ New install method (AssetLib from GodotEngine Editor)

--------------------

**version 0.6.0**  
*removed*   
- old position: 
  - the plugin doesn't appear in docs anymore. Instead, it will load a new tool in the top toolbar
- old layout: 
  - RepositoryList and GistList now show more informations about their contents
- old repository's content system:
  - Repositories contents are now listed in a tree way
- old "commit to repository" system and FILTERS:
  - The old system was based on a Filtering system: I introduced filters to help people choose which file to exclude from your commit, which files should negate an exclusion, and eventually from which path to start. This system was based on the conception that the whole commit started from the `res://` path. Now, you can select in a more interactive way all files and folders you want to commit, and exclude them with a .gitignore system.

*added*  
+ Informations about repositories:
  + Repositories now have their own icons: *lock* for private, *fork* for forked repositories, *gray repo* for own public repositories
  + Repositories show their forked times and stars
+ License templates: new repositories can now be created with a license template from all availables github supported licenses
+ Repository contents system:
  + files are now displayed in a compact, more readable tree system. Files and folders are differentiated, and folders can be folded and unfolded to show their contents
  + you can now delete multiple files just CTRL/SHIFT selecting them. **remember:** folders cannot be deleted by github integrity rules. Delete all folder's contents to delete the folder itself
  + you can now create a new branch from all selectable branches in your repository
+ **!Repository committing system**:  
  + [filtering]  
    + Since FILTERS are not supported anymore, the usage of `.gitignore` is now implemented.
    + a `.gitignore` file is loaded from the repository you want to commit to. If this repository doesn't have a gitignore, an empty and new gitignore can be created and committed.
    + the "gitignore editor" is shown next to the "committing tree" so you can procedurally select files and folders, and exclude/include them with the gitignore. *if you don't know how to use a gitignore, I recommend you to click on the `?` button in the bottom-right of the gitignore editor*
    + the "edit .gitignore" button will prevent any unwanted modifications to be applied by any chance (miss-typing, or you just don't need to edit the gitignore since it was loaded from the repository)  
  + [file choosing]
    + Since FILTERS are not supported anymore, the commit process won't start from the project folder.
    + Now you can select multiple files and directories you want to commit through a file dialog showing your whole project folder.
    + Files and directories can always be removed before committing  
**Please, note that the gitignore filtering method is custom made. To fully support the same gitignore method applied by GitHub some tests are needed**
+ **Gists** can now be opened, edited, and pushed with a cusotm GitEditor. Gists which contain more than one file are supported, and you can edit more files at the same time.

--------------------

**version 0.6.2**  
*fixed*  
- new method to show contents of repositories: faster code and works better. Empty repositories won't be loaded
- now each loading has a loading screen covering the whole scene: no more missclicks during a repository loading or a commit
- new icons in repositories to visually show what's the content type ( adapted to Godot Engine's file types)

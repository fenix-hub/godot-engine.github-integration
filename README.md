# GitHub Integration
A complete GitHub integration for your Godot Editor! Manage your project without even opening your browser.

Author: *"Nicolo (fenix) Santilio"*  
Version: *0.0.1*  
Godot Version: *3.1.1-stable*  

**This repository was pushed directly from Godot Engine Editor!**

## What is this?
*GitHub Integration* is a plugin for Godot Engine that I've created mainly for a personal purpose.  
Pushing and Pulling personal repositories while I'm working on Godot (especially if I'm under a GameJam) could take some time and force me to save the project, open the brwoser/git bash/git gui, and do all the stuff.  
With this little plugin which works directly in the editor, managing all your repositories will be very easy.  

## How does it work?
As soon as you download end activate the plugin, a new tab in the Bottom Left Doc will open, the "GitHub" tab.  
1. Sign in with your credentials: the field *"password"* can also be filled with a *"token"*. To know about GitHub tokens and how to create them, click on the *"Create Token"* button.  
![sign](https://i.imgur.com/mt2Qdwx.png)
2. Once you have signed in, your *"User Panel"* will load. Here you can see your avatar, profile name, number and list of repositories, number and list of gists. You will always see all you repositories and gists in your GitHub account, but the private ones will be tagged with a "lock" icon.  
![profile](https://i.imgur.com/eEntueY.png)
3. With *"New Repository*" and *"New Gist*" buttons you can create a new Repository or Gist.  
![new](https://i.imgur.com/ly71FH0.png)
4. With a **double click** on one of your repositories (or a gists) you will enter the *"Repository*" panel, where you will be able to manage the repository (delete, commit).  
![edit](https://i.imgur.com/Ijabmr9.png)

## How do I install it?
Just download [this whole repository](https://github.com/fenix-hub/godot-engine.github-integration/tree/v0.0.1) and put it in your `res://addons` folder inside the project you want to work on.  
Then, go to `Project > Plugins > "GitHub Integration" > Status > Activate`.  

### current features (v-0.0.1)
- Log in with Password or Token
- Create a new repository
- Create a new gist
- Delete a repository
- Commit and push to a selected repository

### to-come features (v-0.0.x)
+ Automatic Sign-in
+ Pull requests
+ Cloning
+ Merging
+ Repository panel: show branches and content of selected branches
+ Edit repository
+ Create repository: chose branch, edit readme, .gitignor template, license templete
+ Commit and Push to repository: choose a branch , automatic/non-automatic sign
+ Commit and Push multiple files
+ Show gists in internal file editor
+ Delete gists
+ Create gist of multiple files

### What do I want for a v-1.0.0 ?
The first complete and released version will be set once the main operations you can do on GitHub browser and app will be available in this plugin (ex. Committing and Pushing, Branching, Pulling) placed side by side with a full error handling.

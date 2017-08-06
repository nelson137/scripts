#!/bin/bash


errors=("Errors:")


pre-setup() {
	# root passwd
	root-pass() {
		if [[ $# > 0 ]]; then
			sudo echo ""
		fi
		sudo echo "Change root password..."
		sudo passwd root || root-pass "again"
	}
	root-pass
	
	# Home Hierarchy
	echo ""; echo "Setting up home hierarchy..."
	cd "$HOME"
	rm examples.desktop
	mkdir .virtualenvs bin Projects
    cd Projects
    mkdir Bash CPP Deb Git Python Web subl
    cd subl
    ProjectsSublProj='{
    "folders":
    [
        {
            "path": "/home/nelson/Projects"
        }
    ]
}
'
    echo "$ProjectsSublProj" > "Projects.sublime-project"
}


installations() {
	# apt
	echo ""; echo "Aptitude installations..."
	sudo apt-add-repository ppa:webupd8team/sublime-text-3 -y || errors+=("installations: adding the sublime text repository")
	sudo apt-add-repository ppa:neurobin/ppa -y || errors+=("installations: adding the Shc repository")
	sudo apt-get update || errors+=("installations: apt-get update")
	#sudo apt-get upgrade -y || errors+=("installations: apt-get upgrade")
    apt-packages=(vim git virtualenv sublime-text-installer xdotool tmux python3-tk apache2 shc)
    for ap in "${apt-packages[@]}"; do
        sudo apt-get install "$ap" -y || errors+=("installations: apt-get install $ap")
    done
	sudo chown -R `whoami`:`whoami` /var/www/ || errors+=("installations: giving user full permissions to /var/www/")

	# git
	echo ""; echo "Cloning Git tools and repositories..."
	git clone "https://github.com/nelson137/scripts.git" "$HOME/Projects/Git/scripts/" || errors+=("git: cloning scripts")
	git clone "https://github.com/nelson137/wallpapers.git" "$HOME/Projects/Git/wallpapers/" || errors+=("git: cloning wallpapers")
	rm -r "$HOME/Pictures/"
	ln -s "$HOME/Projects/Git/wallpapers/Pictures/" "$HOME/"

    clone-repos() {
        for repo in "${repos[@]}"; do
            git clone "https://github.com/nelson137/${repo}.git" || errors+=("git: cloning $repo")
        done
    }

    cd "$HOME/Projects/Git"
    repos=(config-files scripts)
    clone-repos

    cd ../Python
    repos=(dict myplatform ship-catalog)
    clone-repos

    cd ../Web
    repos=(deep-conversations)
    clone-repos

	# Google Chrome
	echo ""; echo "Installing Google Chrome..."
	wget -O "$HOME/Downloads/google-chrome.deb" "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" || errors+=("Google Chrome: downloading")
	sudo dpkg -i "$HOME/Downloads/google-chrome.deb" || sudo apt-get install -f -y && sudo dpkg -i "$HOME/Downloads/google-chrome.deb" || errors+=("Google Chrome: unpacking")
	rm "$HOME/Downloads/google-chrome.deb" || errors+=("Google Chrome: deleting deb")

	# Tor
	echo ""; echo "Installing Tor..."
	wget -O "$HOME/Downloads/tor.tar.xz" "https://github.com/TheTorProject/gettorbrowser/releases/download/v6.5.1/tor-browser-linux64-6.5.1_en-US.tar.xz" || errors+=("Tor: downloading")
	mkdir "$HOME/tor" && tar -xf "$HOME/Downloads/tor.tar.xz" -C "$HOME/tor/" --strip-components=1 || errors+=("Tor: unpacking")
	rm "$HOME/Downloads/tor.tar.xz" || errors+=("Tor: deleting tar.xz")
}


system() {
	# System Settings
	echo ""; echo "Updating system settings..."
	gsettings set org.gnome.desktop.session idle-delay 1800 || errors+=("system settings: changing the delay for turning the screen off when inactive")
	
	# Virtualenvs
	echo ""; echo "Setting up virtualenvs..."
	virtualenv -p python3.5 "$HOME/.virtualenvs/MainEnv" --system-site-packages || errors+=("MainEnv: creation")
	source "$HOME/.virtualenvs/MainEnv/bin/activate" || errors+=("MainEnv: activating")
	pip install myplatform flask requests || errors+=("MainEnv: installing myplatform, flask, and requests")
	
	# .bashrc
	echo ""; echo "Updating .bashrc..."
	bashrc_text='source ~/.bash_additions'
	ln -s "$HOME/Projects/Git/scripts/Bash/DotFiles/.bash_additions" "$HOME/" || errors+=("bashrc: creating .bash_additions symbolic link")
	if [[ -f $HOME/.bashrc ]]; then
		echo "
$bashrc_text" >> "$HOME/.bashrc"
	else
		echo "$bashrc_text" > "$HOME/.bashrc"
	fi

	# .vimrc
	echo ""; echo "Updating .vimrc..."
	vimrc_text="set whichwrap+=<,>,[,]"
	if [[ -f $HOME/.vimrc ]]; then
		echo "
$vimrc_text" >> "$HOME/.vimrc"
	else
		echo "$vimrc_text" > "$HOME/.vimrc"
	fi

	# Startup Apps
	echo ""; echo "Creating startup app entries..."
	mkdir "$HOME/.config/autostart/"
	term_on_startup_text='[Desktop Entry]
Name=Terminal
Type=Application
Exec=/usr/bin/gnome-terminal
X-GNOME-Autostart-enabled=true
Hidden=false'
	echo "$term_on_startup_text" > "$HOME/.config/autostart/gnome-terminal.desktop"

	# ~/bin
	echo ""; echo "Creating ~/bin symbolic links..."
    scriptsDir="$HOME/Projects/Git/scripts/Bash"
    cd "$scriptsDir"
	files=(*)
	for f in "${files[@]}"; do
		if [[ -f $f ]]; then
			binPath="$HOME/bin/${f%.sh}"
			if [[ ! -f $binPath ]]; then
				ln -s "$scriptsDir/$f" "$binPath"
			fi
		fi
	done
}


visuals() {
	# Launcher Favorites
	echo ""; echo "Updating launcher favorites..."
	gsettings set com.canonical.Unity.Launcher favorites '["unity://expo-icon","application://firefox.desktop","application://google-chrome.desktop","application://gnome-terminal.desktop","application://org.gnome.Nautilus.desktop","application://sublime-text.desktop","unity://running-apps"]' || errors+=("setting the launcher favorites order")

	# Wallpaper
	echo ""; echo "Updating wallpaper..."
	gsettings set org.gnome.desktop.background picture-uri "file://$HOME/Pictures/orion-nebula.jpg" || errors+=("setting the wallpaper")

	# Terminal Profile
	echo ""; echo "Updating Terminal profile..."
	term_profile="/org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9"
	dconf write "$term_profile/visible-name" "'Main'" || errors+=("terminal profile: setting the name")
	#dconf write "$term_profile/default-size-columns" 80 || errors+=("terminal profile: setting the default columns") #default=80
	#dconf write "$term_profile/default-size-rows 24" || errors+=("terminal profile: setting the default rows") #default=24
	dconf write "$term_profile/use-transparent-background" true || errors+=("terminal profile: setting transparent bg")
	dconf write "$term_profile/background-transparency-percent" 50 || errors+=("terminal profile: setting transparent bg %")
	dconf write "$term_profile/cursor-shape" "'ibeam'" || errors+=("terminal profile: setting the cursor shape")
}


programs() {
	# Git
	echo ""; echo "Configuring Git..."
	git config --global user.name "Nelson Earle" || errors+=("git: setting name")
	git config --global user.email "nelson.earle137@gmail.com" || errors+=("git: setting email")
	git config --global push.default simple || errors+=("git: setting the default push")
	
	# Firefox
	echo ""; echo "Configuring Firefox..."
	firefox &
	w=$(xdotool search --sync --all --onlyvisible --pid "$(pgrep firefox)" --name ".*Mozilla Firefox")
	xdotool windowfocus --sync "$w" key "Control_L+q"
	
	while IFS=read -r line; do
		if [[ $line == Path=* ]]; then
			ff_profile="${line:5}"
		fi
	done < "$HOME/.mozilla/firefox/profiles.ini"

	ln "$HOME/Projects/Git/config-files/Firefox/user.js" "$HOME/.mozilla/firefox/$ff_profile/user.js" || errors+=("Firefox: user preferences")

	# Google Chrome
	echo ""; echo "Configuring Google Chrome..."
	google-chrome &
	w=$(xdotool search --sync --all --onlyvisible --pid "$(pgrep chrome)" --name ".*")
	#xdotool windowfocus --sync "$w" mousemove --sync --window "$w" 440 105 click 1
	xdotool windowfocus --sync "$w" key "Return" key "Return"
	w=$(xdotool search --sync --all --onlyvisible --pid "$(pgrep chrome)" --name ".*Google Chrome")
	xdotool windowfocus --sync "$w" key "Control_L+Shift_L+w"
	
	# Sublime Text
	echo ""; echo "Configuring Sublime Text..."
	subl
	w=$(xdotool search --sync --all --onlyvisible --pid "$(pgrep sublime_text)" --name ".*")
	xdotool windowfocus --sync "$w" key "Control_L+q"
	
	wget -O "$HOME/.config/sublime-text-3/Installed Packages/Package Control.sublime-package" "https://packagecontrol.io/Package%20Control.sublime-package" || errors+=("Sublime Text: downloading Package Control")
	"$HOME/Projects/Git/config-files/Sublime/link-files"
}


pre-setup
installations
system
visuals
programs

if [[ ${#errors[@]} > 1 ]]; then
	for e in "${errors[@]}"; do
		echo "$e" >> "$HOME/config-errors.log"
	done
fi

#sudo reboot

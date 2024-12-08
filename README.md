# My Personal dotfiles

I came upon this [article](https://www.atlassian.com/git/tutorials/dotfiles) for handling dotfiles and use it with minor changes. As such the steps below are copied verbatim from the previously mentioned article for easy referral and modified as deemed fit.


## Starting from scratch

If you haven't been tracking your configurations in a Git repository before, you can start using this technique easily with these lines:

```sh
git init --bare $HOME/.myconfig
alias config='/usr/bin/git --git-dir=$HOME/.myconfig/ --work-tree=$HOME'
config config --local status.showUntrackedFiles no
echo "alias config='/usr/bin/git --git-dir=$HOME/.myconfig/ --work-tree=$HOME'" >> $HOME/.zshrc
```

* The first line creates a folder `~/.myconfig` which is a Git bare repository that will track our files.
* Then we create an alias config which we will use instead of the regular git when we want to interact with our configuration repository.
* We set a flag - local to the repository - to hide files we are not explicitly tracking yet. This is so that when you type config status and other commands later, files you are not interested in tracking will not show up as untracked.
* Also you can add the alias definition by hand to your `.zshrc` or use the the fourth line provided for convenience.

I packaged the above lines into a snippet up on Bitbucket and linked it from a short-url. So that you can set things up with:

`curl -Lks http://bit.do/cfg-init | /bin/bash`

After you've executed the setup any file within the $HOME folder can be versioned with normal commands, replacing git with your newly created config alias, like:

```sh
config status
config add .vimrc
config commit -m "Add vimrc"
config add .bashrc
config commit -m "Add bashrc"
config push
```

## Installing your dotfiles onto a new system (or migrate to this setup)

If you already store your configuration/dotfiles in a Git repository, on a new system you can migrate to this setup with the following steps:

Prior to the installation make sure you have committed the alias to your `.bashrc` or `.zsh`:

```sh
alias config='/usr/bin/git --git-dir=$HOME/.myconfig/ --work-tree=$HOME'
```

And that your source repository ignores the folder where you'll clone it, so that you don't create weird recursion problems:

```sh
echo ".myconfig" >> .gitignore
```

Now clone your dotfiles into a bare repository in a "dot" folder of your $HOME:

```sh
git clone --bare <git-repo-url> $HOME/.myconfig
```

Define the alias in the current shell scope:

```sh
alias config='/usr/bin/git --git-dir=$HOME/.myconfig/ --work-tree=$HOME'
```

Checkout the actual content from the bare repository to your $HOME:

```sh
config checkout
```

The step above might fail with a message like:

```sh
error: The following untracked working tree files would be overwritten by checkout:
    .bashrc
    .gitignore
Please move or remove them before you can switch branches.
Aborting
```

This is because your `$HOME` folder might already have some stock configuration files which would be overwritten by Git. The solution is simple: back up the files if you care about them, remove them if you don't care. I provide you with a possible rough shortcut to move all the offending files automatically to a backup folder:

```sh
mkdir -p .config-backup && \
config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | \
xargs -I{} mv {} .config-backup/{}
```

Re-run the check out if you had problems:

```sh
config checkout
```

Set the flag `showUntrackedFiles` to `no` on this specific (local) repository:

```sh
config config --local status.showUntrackedFiles no
```

You're done, from now on you can now type config commands to add and update your dotfiles:

```sh
config status
config add .vimrc
config commit -m "Add vimrc"
config add .bashrc
config commit -m "Add bashrc"
config push
```

Again as a shortcut not to have to remember all these steps on any new machine you want to setup, you can create a simple script, store it as Bitbucket snippet like I did, create a short url for it and call it like this:

```
curl -Lks http://bit.do/cfg-install | /bin/bash
```

For completeness this is what I ended up with (tested on many freshly minted Alpine Linux containers to test it out):

```sh
git clone --bare https://bitbucket.org/durdn/cfg.git $HOME/.cfg
function config {
   /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME $@
}
mkdir -p .config-backup
config checkout
if [ $? = 0 ]; then
  echo "Checked out config.";
  else
    echo "Backing up pre-existing dot files.";
    config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .config-backup/{}
fi;
config checkout
config config status.showUntrackedFiles no
```


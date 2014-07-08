# Load the system-wide profile, if it exists
# Could be a problem if the scripts are bash-biased, but seems OK so far...
[ -r /etc/profile ] && source /etc/profile

# MacPorts
[ -d /opt/local/bin ] && export PATH=/opt/local/bin:$PATH

# Home directory bin
export PATH=$HOME/bin:$PATH

# Local settings
[ -r ${HOME}/.zshenv.local ] && source ${HOME}/.zshenv.local

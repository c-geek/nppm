#!/bin/bash

{ # this ensures the entire script is downloaded #

ucoin_has() {
  type "$1" > /dev/null 2>&1
}

if [ -z "$NPPM_DIR" ]; then
  NPPM_DIR="$HOME/.nppm"
fi

ucoin_latest_version() {
  echo "v0.20.0a47"
}

ucoin_repo_url() {
  echo "https://github.com/c-geek/nppm.git"
}

ucoin_download() {
  if ucoin_has "curl"; then
    curl -qkL $*
  elif ucoin_has "wget"; then
    # Emulate curl with wget
    ARGS=$(echo "$*" | command sed -e 's/--progress-bar /--progress=bar /' \
                           -e 's/-L //' \
                           -e 's/-I /--server-response /' \
                           -e 's/-s /-q /' \
                           -e 's/-o /-O /' \
                           -e 's/-C - /-c /')
    wget $ARGS
  fi
}

install_ucoin_from_git() {

  local PREVIOUS_PATH
  PREVIOUS_PATH=$PATH
  if [ -d "$NPPM_DIR/.git" ]; then
    echo "=> ucoin is already installed in $NPPM_DIR, trying to update using git"
    printf "\r=> "
    cd "$NPPM_DIR" && (command git fetch 2> /dev/null || {
      echo >&2 "Failed to update ucoin, run 'git fetch' in $NPPM_DIR yourself." && exit 1
    })
  else
    # Cloning to $NPPM_DIR
    echo "=> Downloading ucoin from git to '$NPPM_DIR'"
    printf "\r=> "
    mkdir -p "$NPPM_DIR"
    command git clone "$(ucoin_repo_url)" "$NPPM_DIR"
  fi
  cd "$NPPM_DIR"

  # Download Nodejs
  local NVER="5.9.1";
  local ARCH="x86"
  local X64=`uname -a | grep "x86_64"`
  local ARM=`uname -a | grep "arm"`
  if [ ! -z "$X64" ]; then
    ARCH="x64"
  fi
  # ARM processors
  if [ ! -z "$ARM" ]; then
    ARCH="`uname -m`"
  fi
  local NODEJS_FILENAME=node-v${NVER}-linux-${ARCH}
  local NODEJS_TARBALL=http://nodejs.org/dist/v${NVER}/${NODEJS_FILENAME}.tar.gz
  local NODEJS_ARCHIVE=$NPPM_DIR/node.tar.gz
  local NODEJS_EXTRACTED=$NPPM_DIR/$NODEJS_FILENAME
  if [ ! -d "$NPPM_DIR/node" ]; then
    echo "=> Downloading '$NODEJS_TARBALL' to '$NODEJS_ARCHIVE'"
    ucoin_download "$NODEJS_TARBALL" -o "$NODEJS_ARCHIVE" || {
      echo >&2 "Failed to download '$NODEJS_TARBALL'"
      return 4
    }
    tar xzf $NODEJS_ARCHIVE || {
      echo >&2 "Failed to extract '$NODEJS_ARCHIVE'"
      return 5
    }
    mv $NODEJS_FILENAME "node" || {
      echo >&2 "Failed to extract '$NODEJS_ARCHIVE'"
      return 6
    }
  fi

  # Install uCoin dependencies (NPM modules)
  NODE=$NPPM_DIR/node/bin/node
  NPM=$NPPM_DIR/node/bin/npm
  $NPM install
  return
}

#
# Detect profile file if not specified as environment variable
# (eg: PROFILE=~/.myprofile)
# The echo'ed path is guaranteed to be an existing file
# Otherwise, an empty string is returned
#
ucoin_detect_profile() {

  local DETECTED_PROFILE
  DETECTED_PROFILE=''
  local SHELLTYPE
  SHELLTYPE="$(basename /$SHELL)"

  if [ $SHELLTYPE = "bash" ]; then
    if [ -f "$HOME/.bashrc" ]; then
      DETECTED_PROFILE="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
      DETECTED_PROFILE="$HOME/.bash_profile"
    fi
  elif [ $SHELLTYPE = "zsh" ]; then
    DETECTED_PROFILE="$HOME/.zshrc"
  fi

  if [ -z $DETECTED_PROFILE ]; then
    if [ -f "$PROFILE" ]; then
      DETECTED_PROFILE="$PROFILE"
    elif [ -f "$HOME/.profile" ]; then
      DETECTED_PROFILE="$HOME/.profile"
    elif [ -f "$HOME/.bashrc" ]; then
      DETECTED_PROFILE="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
      DETECTED_PROFILE="$HOME/.bash_profile"
    elif [ -f "$HOME/.zshrc" ]; then
      DETECTED_PROFILE="$HOME/.zshrc"
    fi
  fi

  if [ ! -z $DETECTED_PROFILE ]; then
    echo "$DETECTED_PROFILE"
  fi
}

ucoin_do_install() {

  # Check required commands
  if ! ucoin_has "git"; then
    echo "=> git is not available. You will likely need to install 'git' package."
    exit 1
  fi
  if ! ucoin_has "curl"; then
    echo "=> curl is not available. You will likely need to install 'curl' package."
    exit 1
  fi
  if ! ucoin_has "make"; then
    echo "=> make is not available. You will likely need to install 'build-essential' package."
    exit 1
  fi
  if ! ucoin_has "g++"; then
    echo "=> g++ is not available. You will likely need to install 'build-essential' package."
    exit 1
  fi
  if ! ucoin_has "python"; then
    echo "=> python is not available. You will likely need to install 'build-essential' package."
    exit 1
  fi

  install_ucoin_from_git

  echo

#  local UCOIN_PROFILE
#  UCOIN_PROFILE=$(ucoin_detect_profile)

#  SOURCE_STR="\nexport NPPM_DIR=\"$NPPM_DIR\"\n[ -s \"\$NPPM_DIR/duniter.sh\" ] && . \"\$NPPM_DIR/duniter.sh\"  # This loads duniter.sh"
#
#  if [ -z "$UCOIN_PROFILE" ] ; then
#    echo "=> Profile not found. Tried $UCOIN_PROFILE (as defined in \$PROFILE), ~/.bashrc, ~/.bash_profile, ~/.zshrc, and ~/.profile."
#    echo "=> Create one of them and run this script again"
#    echo "=> Create it (touch $UCOIN_PROFILE) and run this script again"
#    echo "   OR"
#    echo "=> Append the following lines to the correct file yourself:"
#    printf "$SOURCE_STR"
#    echo
#  else
#    if ! command grep -qc '/duniter.sh' "$UCOIN_PROFILE"; then
#      echo "=> Appending source string to $UCOIN_PROFILE"
#      printf "$SOURCE_STR\n" >> "$UCOIN_PROFILE"
#    else
#      echo "=> Source string already in $UCOIN_PROFILE"
#    fi
#  fi

  echo "=> ------------------------------------------------------"
  echo "=> !                                                     !"
  echo "=> ! CLOSE and REOPEN YOUR TERMINAL to start using ucoin !"
  echo "=> !                                                     !"
  echo "=> ------------------------------------------------------"
  ucoin_reset
}

#
# Unsets the various functions defined
# during the execution of the install script
#
ucoin_reset() {
  unset -f ucoin_reset ucoin_has ucoin_latest_version \
    ucoin_download install_ucoin_from_git \
    ucoin_detect_profile ucoin_do_install
}

[ "_$UCOIN_ENV" = "_testing" ] || ucoin_do_install $1

} # this ensures the entire script is downloaded #

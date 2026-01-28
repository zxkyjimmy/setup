#!/bin/sh

force_install=false

usage() {
	cat >&2 <<EOF
Usage: $0 [-f | -h]
	-f: Force install (skip the pre-install check)
	-h: Show this usage and exit
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		-f)
			force_install=true
			;;
		-h)
			usage
			exit 0
			;;
		*)
			usage
			exit 1
			;;
	esac
	shift
done

$force_install || {
#!/bin/sh

VERSION=8.42.71

white='\033[0m'
red='\033[91m'
yellow='\033[93m'
green='\033[92m'
blue='\033[94m'
purple='\033[95m'
cyan='\033[96m'

write_report_to_file=false
scanner_compat=0
agent_compat=0
check_python=false

die() {
    error "$1"
    exit 1
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --no-color) white='';red='';yellow='';green='';blue='';purple='';cyan='';;
        --check-python) check_python=true;;
    esac
    shift
done

# Log output
output=''

# Constants
NOT_COMPAT=-1000
MISSING_OK=0

PROCFS_COMPAT=0
PROCFS_NOT_COMPAT=$NOT_COMPAT
SYSFS_COMPAT=0
SYSFS_NOT_COMPAT=$NOT_COMPAT
PKG_COMPAT=1
PKG_NOT_COMPAT=$MISSING_OK
LOG_AUTH_COMPAT=1
LOG_SECURE_COMPAT=1
LOG_BTMP_COMPAT=1
LOG_WTMP_COMPAT=1
LOG_UTMP_COMPAT=1
LOG_SYSLOG_COMPAT=1
LOG_MESSAGES_COMPAT=1
LOG_BASH_COMPAT=3

PY_COMPAT=0
$check_python && PY_NOT_COMPAT=$NOT_COMPAT || PY_NOT_COMPAT=$MISSING_OK

# Agent
DARWIN_MIN_KERNVER=16.0.0
LINUX_MIN_KERNVER=2.6.23
# Engine
MIN_PYVER=2.6.2
MAX_PYVER=3.11.100

# Things to check
os=''
kernver=''
pyver=''
pkg=''

if echo -e '' | grep -F -- -e >/dev/null 2>&1; then
    echo_flag=
else
    echo_flag=-e
fi

say() {
    echo $echo_flag "$1"
    append_output "$1"
}

# add_scanner_compat [num]: the more [num], the more compatible
add_scanner_compat() {
    tmp="${1:-0}"
    scanner_compat=$(expr $scanner_compat + $tmp)
    if [ -z "$2" ]; then
        return 0
    fi

    if [ $tmp -lt 0 ]; then
        error "$2"
    elif [ $tmp -eq 0 ]; then
        info "$2"
    else
        good "$2"
    fi
}

add_agent_compat() {
    tmp="${1:-0}"
    agent_compat=$(expr $agent_compat + $tmp)
    if [ -z "$2" ]; then
        return 0
    fi

    if [ $tmp -lt 0 ]; then
        error "$2"
    elif [ $tmp -eq 0 ]; then
        info "$2"
    else
        good "$2"
    fi
}

append_output() {
    if [ -n "$output" ]; then
        output="$output\n$@"
    else
        output="$@"
    fi
}

log() {
    echo $echo_flag "$@"
    append_output "$@"
}

info() {
    say "${blue}[*]${white} $1"
}

good() {
    say "${green}[+]${white} $1"
}

warn() {
    say "${yellow}[*]${white} $1"
}

error() {
    say "${red}[-]${white} $1"
}

fail() {
    error "$1"
    exit 1
}

section() {
    say "${cyan}[$1]${white}"
}

main() {
    echo "Script version: $VERSION"
    check_system
    check_scanner

    output_report
}

check_system() {
    section System

    arch="$(uname -m)"
    kernel="$(uname -s)"
    if [ "$arch" = "x86_64" ]; then
        add_agent_compat 0 "Arch: x86_64"
    elif [ "$arch" = "arm64" ] && [ "$kernel" = "Darwin" ]; then
        add_agent_compat 0 "Arch: $arch"
    elif [ "$arch" = "aarch64" ] && [ "$kernel" = "Linux" ]; then
        add_agent_compat 0 "Arch: $arch"
    elif [ "$kernel" = "AIX" ] ; then
        if [ "$(getsystype -y)" = "64" ]; then
            add_agent_compat 0 "Arch: ppc64"
        else
            add_agent_compat $NOT_COMPAT "Agent doesn't support $(getsystype -y)-bit powerPC (AIX)"
        fi
    else
        add_agent_compat $NOT_COMPAT "Agent doesn't support arch '$arch'"
    fi

    # kernel version check
    case "$kernel" in
        Darwin)
            kernver=$(uname -r | cut -d- -f1)
            if _is_version_less_than "$kernver" $DARWIN_MIN_KERNVER; then
                add_agent_compat $NOT_COMPAT "Kernel too old: $kernver"
            else
                add_agent_compat 0 "Kernel: $kernver"
            fi
            ;;
        Linux)
            kernver=$(uname -r | cut -d- -f1)
            if _is_version_less_than "$kernver" $LINUX_MIN_KERNVER; then
                add_agent_compat $NOT_COMPAT "Kernel too old: $kernver"
            else
                add_agent_compat 0 "Kernel: $kernver"
            fi
            ;;
    esac

    # OS
    os=$(_get_os)
    if [ $? -ne 0 ]; then
        add_scanner_compat 0 "Not officially supported: $os"
    else
        add_scanner_compat 0 "Officially supported OS: $os"
    fi
    if [ "$(uname -s)" = Linux ]; then
        check_init
        check_libc
    fi

    if [ $(df -P /tmp|awk 'NR==2{print$4}') -gt 102400 ]; then
        add_agent_compat 0 "Enough disk size for /tmp: $(get_dir_avail_size /tmp)"
    else
        add_agent_compat $NOT_COMPAT "Not enough disk size for /tmp: $(get_dir_avail_size /tmp) (need 100MB)"
    fi

    if [ $(df -P /var/log|awk 'NR==2{print$4}') -gt 102400 ]; then
        add_agent_compat 0 "Enough disk size for /var/log: $(get_dir_avail_size /var/log)"
    else
        add_agent_compat $NOT_COMPAT "Not enough disk size for /var/log: $(get_dir_avail_size var/log) (need 100MB)"
    fi

    if [ "$os" != AIX ]; then
        varlib_size=409600 # MPM pattern
        varlib_human='400MB'
    else
        varlib_size=102400
        varlib_human='100MB'
    fi

    if [ $(df -P /var/lib|awk 'NR==2{print$4}') -gt $varlib_size ]; then
        add_agent_compat 0 "Enough disk size for /var/lib: $(get_dir_avail_size /var/lib)"
    else
        add_agent_compat $NOT_COMPAT "Not enough disk size for /var/lib: $(get_dir_avail_size var/lib) (need $varlib_human)"
    fi
}

get_dir_avail_size() {
    out="$(df -Ph "$1" 2>/dev/null)"
    [ $? -eq 0 ] && \
        echo "$out" | awk 'NR==2{print$4}' || \
        df -P "$1"|awk 'NR==2{print$4}'
}

check_init() {
    _is_container && add_agent_compat 0 "Init system: container" && return 0

    _init=$(_get_init_system)
    test $? -eq 0 && add_agent_compat 0 "Init system: $_init" && return 0
    add_agent_compat $NOT_COMPAT "No compatible init system found"
}

_is_container() {
    egrep '[a-fA-F0-9]{64}$' /proc/self/cpuset >/dev/null 2>&1
}

_get_init_system() {
    # /proc/[pid]/comm (since 2.6.33)
    case "$(cat /proc/1/comm 2>/dev/null||echo init)" in
        systemd)
            test -d /run/systemd/system && echo systemd && return 0
            ;;
        upstart)
            test -d /etc/init && echo upstart && return 0
            ;;
        init)
            test -d /etc/init.d && echo init && return 0
            ;;
    esac
    echo unknown
    return 1
}

_version_part() {
    echo "$1" | cut -d. -f$2
}

# _is_version_less_than 1.2.3 1.2.4  # true
_is_version_less_than() {
    this="$1"
    other="$2"

    if [ -z "$this" -o -z "$other" ]; then
        fail "Comparing empty versions: '$this' v.s. '$other'"
    fi

    for i in 1 2 3; do
        n1=$(_version_part "$this" $i)
        n2=$(_version_part "$other" $i)
        test $n1 -lt $n2 && return 0
        test $n1 -gt $n2 && return 1
    done
    return 1
}

_get_os() {
    os="$(uname -s)"
    case "$os" in
        Darwin)
            echo macOS "$(sw_vers|grep ^ProductVersion|awk '{print $2}')"
            return 0
            ;;
        Linux)
            tmp=$(lsb_release -a 2>/dev/null; cat /etc/issue 2>/dev/null; cat /etc/*release 2>/dev/null)
            for os in Ubuntu Debian CentOS; do
                echo "$tmp" | grep -i $os >/dev/null 2>&1 && log $os && return 0
            done
            echo "$tmp" | grep -i 'Red Hat Enterprise' >/dev/null 2>&1 && log RHEL && return 0
            head -n1 /etc/issue 2>/dev/null
            ;;
        AIX)
            echo AIX && return 0;;
        *)
            echo "$os"
            ;;
    esac
    return 1
}

check_libc() {
    libc="$(ldd /bin/sh | grep -F libc. | sed 's/^[ \t]*//')"
    ldd /bin/sh 2>/dev/null | grep /libc.so.6 >/dev/null
    if [ "$?" -eq 0 ]; then
        add_agent_compat 0 "Compatible libc: $libc"
    else
        add_agent_compat $NOT_COMPAT "Incompatible libc: $libc"
    fi
    unset libc
}

check_scanner() {
    section Scanner
    check_python
    if [ "$(uname -s)" = Linux ]; then
        check_procfs
        check_sysfs
        check_package
        check_log
    fi
}

check_python() {
    if _has_command python; then
        py=$(_which_command python)
    elif _has_command python3; then
        py=$(_which_command python3)
    elif test -f /usr/libexec/platform-python; then
        py=/usr/libexec/platform-python
    elif test -f /usr/libexec/platform-python3; then
        py=/usr/libexec/platform-python3
    else
        add_scanner_compat $PY_NOT_COMPAT "Python not installed"
        return 1
    fi
    pyver=$($py -V 2>&1 | egrep -o '[0-9]+[.][0-9]+[.][0-9]+')
    [ -z "$pyver" ] && add_scanner_compat $PY_NOT_COMPAT "Python ($py) is not functional" && return 1
    _is_version_less_than $pyver $MIN_PYVER && add_scanner_compat $PY_NOT_COMPAT "Python $pyver" && return 1
    _is_version_greater_than $pyver $MAX_PYVER && add_scanner_compat $PY_NOT_COMPAT "Python $pyver" && return 1
    missing=$(cat <<! | $py
import sys
pkgs = (
    'atexit',
    'base64',
    'binascii',
    'calendar',
    'codecs',
    'collections',
    ('configparser', 'ConfigParser'),
    'contextlib',
    'copy',
    'ctypes',
    'datetime',
    'errno',
    'fnmatch',
    'functools',
    'glob',
    'gzip',
    'hashlib',
    'inspect',
    'io',
    'itertools',
    'json',
    'logging',
    'mmap',
    'multiprocessing',
    'operator',
    'os.path',
    'pipes',
    'platform',
    'pwd',
    're',
    'resource',
    'shlex',
    'signal',
    'socket',
    'stat',
    'string',
    'struct',
    'subprocess',
    'sys',
    'tempfile',
    'time',
    'traceback',
    'uuid',
    'zlib',
)
missing = []
for pkg in pkgs:
    if isinstance(pkg, tuple):
        for alt in pkg:
            try:
                __import__(alt)
                break # found at least 1 alternative
            except Exception:
                pass
        else:
            missing.append(pkg[0])
    else:
        try:
            __import__(pkg)
        except Exception:
            missing.append(pkg)
if missing:
    sys.stdout.write(', '.join(missing))
    sys.exit(1)
sys.exit(0)
!
)
    test $? -eq 0 || { add_scanner_compat $NOT_COMPAT "Missing python packages: $missing" && return 1; }
    add_scanner_compat 0 "Python $pyver ($py)"
}

_is_version_greater_than() {
    _is_version_less_than "$2" "$1"
}

_has_command() {
    if command -v sh >/dev/null 2>&1; then
        command -v "$1" >/dev/null 2>&1
    else
        which "$1" >/dev/null 2>&1
    fi
}

_which_command() {
    if command -v sh >/dev/null 2>&1; then
        command -v "$1"
    else
        which "$1"
    fi
}

check_procfs() {
    test -d /proc || { error "No /proc"; add_scanner_compat $PROCFS_NOT_COMPAT; return 1; }
    test -f /proc/1/task/1/sched \
        && test -h /proc/1/exe \
        && test -d /proc/net \
        && test -d /proc/self \
        && test -d /proc/self/net \
        && test -f /proc/1/status \
        && test -f /proc/1/cmdline \
        && test -d /proc/1/fd \
        && test -f /proc/1/stat \
        || { error "Not Linux /proc"; add_scanner_compat $PROCFS_NOT_COMPAT; return 1; }
    add_scanner_compat $PROCFS_COMPAT "Standard Linux /proc"
    return 0
}

check_sysfs() {
    test -d /sys || { error "No /sys"; add_scanner_compat $SYSFS_NOT_COMPAT; return 1; }
    test -d /sys/firmware \
        && test -d /sys/class \
        && test -d /sys/devices \
        || { error "Not Linux /sys"; add_scanner_compat $SYSFS_NOT_COMPAT; return 1; }
    add_scanner_compat $SYSFS_COMPAT "Standard Linux /sys"
    return 0
}

check_package() {
    for tmp in dpkg rpm; do
        if _has_command "$tmp"; then
            pkg="$tmp"
            add_scanner_compat $PKG_COMPAT "Package system: $pkg"
            return 0
        fi
    done
    add_scanner_compat $PKG_NOT_COMPAT "Unknown package system"
    return 1
}

check_log() {
    test -f /var/log/auth.log && add_scanner_compat $LOG_AUTH_COMPAT "/var/log/auth.log"
    test -f /var/log/secure && add_scanner_compat $LOG_SECURE_COMPAT "/var/log/secure"
    test -f /var/log/btmp && add_scanner_compat $LOG_BTMP_COMPAT "/var/log/btmp"
    test -f /var/log/wtmp && add_scanner_compat $LOG_WTMP_COMPAT "/var/log/wtmp"
    test -f /var/run/utmp && add_scanner_compat $LOG_UTMP_COMPAT "/var/run/utmp"
    test -f /var/log/syslog && add_scanner_compat $LOG_SYSLOG_COMPAT "/var/log/syslog"
    test -f /var/log/messages && add_scanner_compat $LOG_MESSAGES_COMPAT "/var/log/messages"
    head -n1 ~/.bash_history 2>/dev/null | grep -E '^#[ ]*[0-9]+' >/dev/null 2>&1 && add_scanner_compat $LOG_BASH_COMPAT "bash history with timestamp"
}

output_report() {
    section Compatibility
    if [ $scanner_compat -ge 0 ]; then
        log "Scanner: ${green}Compatible${white}"
    else
        log "Scanner: ${red}Incompatible${white}"
    fi
    if [ $agent_compat -ge 0 ]; then
        log "Agent: ${green}Compatible${white}"
    else
        log "Agent: ${red}Incompatible${white}"
    fi

    if $write_report_to_file; then
        tmp=$(mktemp --suffix=.gz)
        echo "$output"|gzip -c > $tmp

        info "Bring home: ${yellow}$tmp${white}"
    fi
}

main

(test ${scanner_compat:-0} -lt 0 || test ${agent_compat:-0} -lt 0 || test ${compat:-0} -lt 0) && exit 2
}

cat <<"EOF" | /bin/sh
(debug=${debug:-false};[ "$debug" != "false" ] && debug=true || debug=false;download_log=/dev/null;$debug && set -x && download_log=/tmp/xensor_installer.err;xensor_url="https://10.109.234.120:443";xensor_url_http="$(echo "$xensor_url" | sed s/https/http/g)";[ -n "443" ] && xensor_url_http="$(echo "$xensor_url_http" | sed s/:443/:80/g)";fetch_proxy="";[ -n "$fetch_proxy" ] && export http_proxy="$fetch_proxy" && export https_proxy="$fetch_proxy";curl="curl${fetch_proxy:+ -x $fetch_proxy}";appid=A00003;uid=$(id -u);[ $uid -ne 0 ] && sudo=sudo && $sudo -v || [ $uid -eq 0 ] || { echo Please run as root or sudoer; exit 1; };agent=cydroned;install_dir=/usr/local/bin;[ -f $install_dir/$agent ] && (($install_dir/$agent -id|grep ^En >/dev/null 2>&1&&pgrep $agent >/dev/null 2>&1;) || (rm -f $install_dir/$agent; false;);) && echo >&2 Already installed or running && exit 1;chmod_x="$sudo chmod +x $agent";cur_os=$(uname|tr A-Z a-z|sed s/aix/linux/g);case "$(uname -m)" in x86) arch=386;; x86_64) arch=amd64;; aarch64|arm64) arch=arm64;; *) arch=ppc64;; esac;case "$appid" in *3) installer_os=linux;; *5) installer_os=darwin;; esac;[ "$cur_os" != "$installer_os" ] && echo >&2 "ERROR: You are trying to install $installer_os agent on $cur_os" && exit 1;xdl_path="xdl/_/$appid/$arch/$cur_os/$agent";install_cmd="$sudo ./$agent -sync 5 -url $xensor_url -apikey 1a36c2c70c3542a38f0c2efdb3da1ea4 -pubkey MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArh0qQ26cUAovxDlfQbXMWBd5A1yRmIB9qdtRZ7JBQ/dJYkC2i/4hl2ceD0H5WXPnQ1qgZ5BOGDLcusiL46fIPSPlS2wJDllHB9RzG8mFwLjpxS6cHl2PpmbSULKIdfD/bHtqIDeBtQqjkz0b1hbzXiWK5Dpx97lWJXhhl36Yi+kBc+x9gY/g0hJnzGBgWEPJgoxaxjVGG/EYaBl+J2cBvIjCiUF3FTijPsH+dv26LqL6RlBKGUWqt1tiy1uFr9Lp/NyYAeqYgRDqZYaALKZ07GJF4hbfJQ74Xo150Pl4cr6WZ3lt+PhkxpGJU7St0vPJB8DQiRoeJlo48Ot9UEMARwIDAQAB -background";(((test -f $agent && ./$agent -id|grep ^En >/dev/null 2>&1;) && (mkdir -p $install_dir;cp $agent $install_dir;cd $install_dir;$chmod_x && $install_cmd;);) || ($sudo mkdir -p $install_dir;cd $install_dir;rm -f $agent;export PERL_LWP_SSL_VERIFY_HOSTNAME=0;(for path in $xdl_path $appid/$agent; do for base_url in $xensor_url $xensor_url_http; do url=$base_url/$path;$sudo wget --no-check-certificate -qO $agent $url 2>>$download_log && exit 0;$sudo $curl -kLo $agent $url 2>>$download_log && exit 0;$sudo perl -e "use LWP::Simple;is_error(getstore('$url','$install_dir/$agent')) and die;" 2>>$download_log && exit 0;$sudo perl -e '$url=shift; $file_to_save=shift; die "Invalid URL" unless $url=~m{^(https?)://([^/:]+)(?::(\d+))?(/.*)}; $scheme=$1; $host=$2; $port=$3//($scheme eq "https"?443:80);$path=$4; if($scheme eq "https"){require IO::Socket::SSL; IO::Socket::SSL->import; $sock=IO::Socket::SSL->new(PeerHost=>$host,PeerPort=>$port,SSL_verify_mode=>IO::Socket::SSL::SSL_VERIFY_NONE) or die "SSL socket: $!\n";}else{require IO::Socket::INET; IO::Socket::INET->import; $sock=IO::Socket::INET->new(PeerAddr=>$host,PeerPort=>$port) or die "Socket: $!\n";} print $sock "GET $path HTTP/1.1\r\nHost: $host\r\nConnection: close\r\n\r\n"; open(my $file, ">", $file_to_save) or die "File: $!\n"; $headers_finished=0; while(<$sock>){if(!$headers_finished && $_ eq "\r\n"){$headers_finished=1;next;}print $file $_ if $headers_finished;} close($file); close($sock);' "$url" "$install_dir/$agent" 2>>$download_log && exit 0;done; done;echo >&2 All download methods failed;exit 1;) && ((case "$cur_os" in linux) head -c4 $agent|tail -c3|grep ELF>/dev/null;; aix) file $agent | grep XCOFF>/dev/null;; darwin) file $agent | grep Mach-O>/dev/null;; *) echo >&2 Unsupported system: $cur_os; exit 1;; esac;) || (echo >&2 "Corrupt file was downloaded: $(file $agent | head -n1)";exit 1;);) && $chmod_x && $install_cmd;);) || ($debug && [ -f "$download_log" ] && echo >&2 "==== Download log ====" && cat >&2 "$download_log" && echo >&2 "====================" && rm -f "$download_log";echo >&2 Installation failed;echo >&2 "Please download $xensor_url/$xdl_path manually and run this command as root or sudoer: $chmod_x && $install_cmd";rm -f $install_dir/$agent;exit 1;);) && echo Agent is up and running;# appid="A00003" group="資創中心(研究)" xensor="https://10.109.234.120:443" proxy="" pac="" fetch_proxy="" taskmgr="0.51.40" created_at="2024-12-25T09:55:11+08:00"
EOF


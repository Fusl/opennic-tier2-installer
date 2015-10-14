#!/usr/bin/env bash

# TODO: Write init.d scripts for cjdns/cjdroute and dnscrypt-wrapper
# TODO: Extend repo and script for RH*, SuSE, Fedora, Arch

die() {
	exitcode="$1"; shift
	echo "$@" 1>&2
	exit "$exitcode"
}

whatdistri() {
	# Distribution is Debian or similar
	test -f /etc/debian_version && echo "debian" && return

	# Distribution is SuSE or similar
	test -f /etc/SuSE-release && echo "suse" && return

	# Distribution is RedHat, CentOS, Scientific or similar
	test -f /etc/redhat-release && echo "redhat" && return

	die 1 "Couldn't detect the linux distribution you're using. Please report this issue with as much information as possible at https://github.com/Fusl/opennic-tier2-installer/issues"
}
whatversion() {
	test -f /etc/debian_version && sed 's/\..*//' /etc/debian_version && return

	test -f /etc/SuSE-release && grep -E "^VERSION" /etc/SuSE-release | sed -r 's/\w+ = //;s/\..*//' && return

	test -f /etc/redhat-release && sed -r 's/\w+ \w+ //;s/\..*//' /etc/redhat-release && return
}

#pkgcmd_centos="yum"
#pkgcmdi_centos="-y install"
#mpkgcmd_centos="yum"
#prepackages_centos="https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
#packages_centos="yum install git python curl fping @development-tools"

realpath=$(realpath "$0")
workdir=$(dirname "$realpath")
distri=$(whatdistri)
version=$(whatversion)

cd "$workdir"

case "$distri" in
	debian)
		versionname=
		case "$version" in
			8)
				versionname=jessie
			;;
			7)
				versionname=wheezy
			;;
			*)
				die 3 "This script is not compatible with $distri $version yet."
			;;
		esac
		mkdir -p "/etc/dnscrypt-wrapper/" "/etc/cron.d/" "/usr/local/src/cjdns-$$/"
		apt-get update
		apt-get -y --no-install-recommends install git python curl fping build-essential ca-certificates wget dnsutils pdns-recursor libsodium libevent-dev
		echo "deb http://repo.meo.ws/debian/ $versionname main" > /etc/apt/sources.list.d/fvzrepo.list
		wget -qO- https://scr.meo.ws/paste/2015-10-07-16-37-22-6gIhrLDm.txt | apt-key add -
		apt-get update
		apt-get -y --no-install-recommends install dnscrypt-wrapper
		test -f /etc/dnscrypt-wrapper/fingerprint || (
			cd /etc/dnscrypt-wrapper/
			dnscrypt-wrapper --gen-provider-keypair | egrep '^Public key fingerprint' | awk '{print $4}' > /etc/dnscrypt-wrapper/fingerprint
			dnscrypt-wrapper --gen-crypt-keypair
			dnscrypt-wrapper --crypt-secretkey-file crypt_secret.key --provider-publickey-file=public.key --provider-secretkey-file=secret.key --gen-cert-file
		)
		git clone "https://github.com/cjdelisle/cjdns.git" "/usr/local/src/cjdns-$$/"
		cd "/usr/local/src/cjdns-$$/"
		./do
		cp -f cjdroute "/usr/local/bin/cjdroute"
		cd "$workdir"
		rm -rf "/usr/local/src/cjdns-$$/"

		cp files/etc/dnscrypt-wrapper/start.sh /etc/dnscrypt-wrapper/start.sh
		cp files/etc/cron.d/dnscrypt /etc/cron.d/dnscrypt
		cp files/etc/powerdns/recursor.conf /etc/powerdns/recursor.conf
		cp files/etc/powerdns/recursor.lua /etc/powerdns/recursor.lua
		cp files/etc/cron.d/recursor /etc/cron.d/recursor
		chmod +x /etc/dnscrypt-wrapper/start.sh
		/etc/dnscrypt-wrapper/start.sh restart
		/etc/init.d/pdns-recursor restart
		test -f /etc/cjdroute.conf || cjdroute --genconf > /etc/cjdroute.conf
	;;
	*)
		die 2 "This script is not compatible with $distri yet."
	;;
esac
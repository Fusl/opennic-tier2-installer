#!/bin/bash

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

if [ "x$1" == "xrestart" ]; then
	needsleep=$(pgrep -f '^(/usr/local/bin/dnscrypt-wrapper|/usr/local/sbin/dnscrypt-wrapper|dnscrypt-wrapper) ' > /dev/null 2> /dev/null; echo -n $?)

	# Killing previous running dnscrypt-wrappers
	pkill -f '^(/usr/local/bin/dnscrypt-wrapper|/usr/local/sbin/dnscrypt-wrapper|dnscrypt-wrapper) '

	# Waiting for ports to become free
	if [ "x$needsleep" == "x0" ]; then
		sleep 90
	fi
fi

ports=54,443,1053,1194,5353,8080,27015

ip4=0.0.0.0
ip6=::

# Hook up all dnscrypt-wrappers
for ip in $(echo -n "$ip6" | sed 's/,/ /g' | sed 's/ /] [/g' | sed -r 's/^(.{1,})$/[\1]/') $(echo -n "$ip4" | sed 's/,/ /g'); do
	for port in $(echo "$ports" | sed 's/,/ /g'); do
		escip=$(echo "$ip" | sed -r 's/(\[|\])/\\\1/g')
		pgrep -f "^(/usr/local/bin/dnscrypt-wrapper|/usr/local/sbin/dnscrypt-wrapper|dnscrypt-wrapper) -U -r 127.0.0.1:53 -a $escip:$port " > /dev/null 2> /dev/null || dnscrypt-wrapper -U -r 127.0.0.1:53 -a $ip:$port --crypt-secretkey-file=/etc/dnscrypt-wrapper/crypt_secret.key --provider-secretkey-file=/etc/dnscrypt-wrapper/secret.key --provider-publickey-file=/etc/dnscrypt-wrapper/public.key --provider-cert-file=/etc/dnscrypt-wrapper/dnscrypt.cert --provider-name=2.dnscrypt-cert.local -d > /dev/null 2> /dev/null
	done
done

exit 0
#!/usr/bin/env sh

: "${ircdir:=$HOME/irc}"
: "${nick:=$USER}"

# server info functions
freenode() {
	server='irc.freenode.net'
	channels="#foo #bar"
}

oftc() {
	server='irc.oftc.net'
	channels="#xyz #abc"
}

# these match the functions above
networks="freenode oftc"

# some privacy please, thanks
chmod 700 "$ircdir"
chmod 600 "$ircdir"/*/ident &>/dev/null

for network in $networks; do
	unset server channels port
	"$network" # set the appropriate vars

	while true; do
		# cleanup
		rm -f "$ircdir/$server/in"

		# connect to netwrok -- password is set through the env var synonym to the network name
		iim -i "$ircdir" -n "$nick" -k "$network" -s "$server" -p "${port:-6667}" &
		pid="$!"

		# wait for the connection
		while ! test -p "$ircdir/$server/in"; do sleep .3; done

		# auth to services
		if [ -e "$ircdir/$server/ident" ]
		then printf "/j nickserv identify %s\n" "$(cat "$ircdir/$server/ident")" > "$ircdir/$server/in"
		fi && rm -f "$ircdir/$server/nickserv/out" # clean that up - ident passwd is in there

		# join channels
		printf "/j %s\n" $channels > "$ircdir/$server/in"

		# if connection is lost reconnect
		wait "$pid"
	done &
done


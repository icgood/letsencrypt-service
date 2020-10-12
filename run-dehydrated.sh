#!/bin/bash -e

[ -n "$CERTS" ] || { echo "empty \$CERTS"; exit 1; }
[ -r $LEXICON_ENV ] || { echo "invalid \$LEXICON_ENV"; exit 1; }
[ -d $BASEDIR ] || { echo "invalid \$BASEDIR"; exit 1; }
[ -d $OUTDIR ] || { echo "invalid \$OUTDIR"; exit 1; }

echo "BASEDIR='$BASEDIR'" >> /etc/dehydrated/config
echo "DOMAINS_TXT='/etc/dehydrated/domains.txt'" >> /etc/dehydrated/config
if [ "$STAGING" = "true" ]; then
	echo "CA='https://acme-staging.api.letsencrypt.org/directory'" >> /etc/dehydrated/config
fi

dehydrated --register --accept-terms

if [ ! -f /etc/dehydrated/domains.txt ]; then
	for cert in $CERTS; do
		primary_var="DOMAIN_$cert"
		alts_var="ALTS_$cert"
		primary=${!primary_var}
		alts=${!alts_var}
		[ -n "$primary" ] || { echo "empty \$$primary_var"; exit 1; }
		echo "$primary $alts > $cert" >> /etc/dehydrated/domains.txt
	done
fi

source $LEXICON_ENV

[ -n "$PROVIDER" ] || { echo "empty \$PROVIDER"; exit 1; }
[ -n "$(bash -c 'echo -n $PROVIDER')" ] || { echo "un-exported \$PROVIDER"; exit 1; }

if [ ! -f $OUTDIR/last-update ]; then
	touch $OUTDIR/last-update
fi

while true; do
	dehydrated --cron \
		--hook /usr/local/bin/lexicon-hook.sh \
		--challenge dns-01 \
		--out $OUTDIR

	if find $OUTDIR -type f -newer $OUTDIR/last-update | read; then
		touch $OUTDIR/last-update
	fi

	sleep_for=$(datediff now "$(dateadd today +1d) 03:00" -f %Ss)
	echo "Sleeping $sleep_for..."
	sleep $sleep_for
done

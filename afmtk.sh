[ ! "$MODPATH" ] && MODPATH=${0%/*}

MODPOL=`find $MODPATH -type f -name audio_policy.conf`
MODCONF=`find $MODPATH -type f -name audio_policy_configuration.xml`

# enable high-sampling rate options up to 192kHz:
for MODCONFIG in $MODCONF; do
    sed -i 's|samplingRates="44100 48000"|samplingRates="44100 48000 96000 192000"|' $MODCONF
done

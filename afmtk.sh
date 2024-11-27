[ ! "$MODPATH" ] && MODPATH=${0%/*}

MODPOL=`find $MODPATH -type f -name audio_policy.conf`
MODCONF=`find $MODPATH -type f -name audio_policy_configuration.xml`

# check for the existence of the deep_buffer tags:
for MODCONFIG in $MODCONF; do
    DEEP_BUFFER=$(grep -c '<mixPort name="deep_buffer"' $MODCONF)
    if [[ $DEEP_BUFFER -eq 0 ]]; then
         sed -i '64a\
                <mixPort name="deep_buffer" role="source" flags=AUDIO_OUTPUT_FLAG_DEEP_BUFFER"> \
                    <profile name="" format="AUDIO_FORMAT_PCM_32_BIT" \
                             samplingRates="44100 48000" channelMasks="AUDIO_CHANNEL_OUT_STEREO"/> \
                    <profile name="" format="AUDIO_FORMAT_PCM_16_BIT" \
                             samplingRates="44100 48000" channelMasks="AUDIO_CHANNEL_OUT_STEREO"/> \
                </mixPort>' $MODCONF
         fi
done

# enable high-sampling rate options up to 192kHz:
for MODCONFIG in $MODCONF; do
    sed -i 's|samplingRates="44100 48000"|samplingRates="44100 48000 96000 192000"|' $MODCONF
done

# Enable Dynamic Range Control (DRC) if disable:
for MODCONFIG in $MODCONF; do
    sed -i '/speaker_drc_enabled="false"/s/false/true/' $MODCONF
done

# highest gain for highest volume level for speaker:
for MODCONFIG in $MODCONF; do
    sed -i '/maxValueMB="4000"/s/4000/8000/' $MODCONF
done

# using deep_buffer for default flags
for MODPOLICY in $MODPOL; do
    sed -i 's|flags AUDIO_OUTPUT_FLAG_PRIMARY|flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER|' $MODPOL
done

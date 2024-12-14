[ ! "$MODPATH" ] && MODPATH=${0%/*}

MODPOL=$(find "$MODPATH" -type f -name audio_policy.conf)
MODCONF=$(find "$MODPATH" -type f -name audio_policy_configuration.xml)

echo ""
echo "  Checking SDK version"; sleep 2
SDK=$(getprop ro.build.version.sdk)
echo "  SDK : $SDK (API)"
if [ "$SDK" -eq 31 ]; then
    sleep 1
    echo "  SDK version is supported. Continuing..."
else
    echo "  Android (SDK) version is not supported!"
    echo "  Module not installed!"
    echo ""
    exit 1
fi

sleep 1
echo ""
echo "• Search for DEEP_BUFFER Property:"
DBPROP=$(getprop audio.deep_buffer.media)
if [ -z "$DBPROP" ]; then
    sleep 2
    echo "  audio.deep_buffer.media property not found!"
    echo "  trying to force enable the property"
        resetprop -n audio.deep_buffer.media true
        sleep 3
    echo "  audio.deep_buffer.media is $(getprop audio.deep_buffer.media)"
else
    if [ "$DBPROP" == false ]; then
        resetprop -n audio.deep_buffer.media true
        sleep 2
    else
        echo "  audio.deep_buffer.media is $DBPROP"
    fi
fi


for CONFIG in $MODCONF; do
    DEEP_BUFFER=$(grep -c '<mixPort name="deep_buffer"' "$CONFIG")
    if [[ $DEEP_BUFFER -eq 0 ]]; then
        sed -i '64a\
        <mixPort name="deep_buffer" role="source" flags="AUDIO_OUTPUT_FLAG_DEEP_BUFFER"> \
            <profile name="" format="AUDIO_FORMAT_PCM_32_BIT" \
                     samplingRates="44100 48000" channelMasks="AUDIO_CHANNEL_OUT_STEREO"/> \
            <profile name="" format="AUDIO_FORMAT_PCM_16_BIT" \
                     samplingRates="44100 48000" channelMasks="AUDIO_CHANNEL_OUT_STEREO"/> \
        </mixPort>' $CONFIG
    fi
done

echo ""
echo "• Checking Sampling Rates:"; sleep 2
SAMPLERATE=$(grep 'samplingRates="44100 48000"' "$MODCONF" | sed -E 's/.*samplingRates="([^"]+)".*/\1/' | head -n 1)
    echo "  SamplingRates: $SAMPLERATE"
if [ "$SAMPLERATE" = "44100 48000" ]; then
    echo "- Enabling High Sampling Rates:"
    sleep 1
    sed -i 's|samplingRates="44100 48000"|samplingRates="44100 48000 96000 192000"|' "$MODCONF"
else
    echo "  ERROR! Device not using 44.1kHz/48kHz"
    echo ""
fi

HSR=$(grep 'samplingRates="44100 48000 96000 192000"' "$MODCONF" | sed -E 's/.*samplingRates="([^"]+)".*/\1/' | head -n 1)
    sleep 2
    echo "  SamplingRates: $HSR"
if [ "$HSR" = "44100 48000 96000 192000" ]; then
    sleep 1
    echo "  Success! device using High Sampling Rates."
fi

echo ""
echo "• Checking Dynamic Range Control (DRC):"
DRC=$(grep 'speaker_drc_enabled' $MODCONF | sed -n 's/.*speaker_drc_enabled="\([^"]*\)".*/\1/p')
if [ $DRC == false ]; then
    sleep 2
    echo "  DRC : $DRC"
    sleep 1
    echo "- Enabling Dynamic Range Control (DRC):"
    sed -i '/speaker_drc_enabled="false"/s/false/true/' $MODCONF
fi

DRCT=$(grep 'speaker_drc_enabled' "$MODCONF" | sed -n 's/.*speaker_drc_enabled="\([^"]*\)".*/\1/p')
if [ $DRCT == true ]; then
    sleep 2
    echo "  DRC : $DRCT"
    echo "  Success, DRC is Enabled!"
fi

echo ""
echo "• Checking GAIN value:"; sleep 2
GAIN=$(grep 'maxValueMB' "$MODCONF" | sed -n 's/.*maxValueMB="\([^"]*\)".*/\1/p')
if [ $GAIN == 4000 ]; then
    sleep 1
    echo "  GAIN : $GAIN"
    sleep 1
    echo "- Enabling Higher GAIN value:"
        sed -i '/maxValueMB="4000"/s/4000/8000/' $MODCONF
        sleep 3
fi

GAIN=$(grep 'maxValueMB' "$MODCONF" | sed -n 's/.*maxValueMB="\([^"]*\)".*/\1/p')
if [ $GAIN == 8000 ]; then
    sleep 2
    echo "  GAIN : $GAIN"
    echo "  Success!"
fi

echo ""
echo "• Checking FLAGS status:"; sleep 2
FLAGS=$(grep -A 5 'flags AUDIO_OUTPUT_FLAG_PRIMARY' $MODPOL | head -n 1)
if [[ -z "$FLAGS" ]]; then
    echo "  FLAG_PRIMARY not found! change to FLAG_DEEP_BUFFER"
    sleep 1
else
    echo "  status : $FLAGS"
    echo "- Enabling FLAG_DEEP_BUFFER:"
    sed -i 's|flags AUDIO_OUTPUT_FLAG_PRIMARY|flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER|' $MODPOL
    sleep 2
fi

FLAGD=$(grep -A 5 'flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER' $MODPOL | head -n 1)
if [[ -z $FLAGD ]]; then
    echo "  FLAG_DEEP_BUFFER not found!"
    sleep 1
else
    sleep 2
    echo "  status : $FLAGD"
    echo "  FLAG_DEEP_BUFFER is enabled!"
    echo "  Success!"
    echo ""
fi

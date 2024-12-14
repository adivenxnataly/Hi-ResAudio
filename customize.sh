[ ! "$MODPATH" ] && MODPATH=${0%/*}

. $MODPATH/copy.sh

MODPOL=$(find "$MODPATH" -type f -name audio_policy.conf)
MODCONF=$(find "$MODPATH" -type f -name audio_policy_configuration.xml)

ui_print ""
ui_print "  Android version : $(getprop ro.build.version.release)"
ui_print "  Name : $(grep_prop name $MODPATH/module.prop)"
ui_print "  Version : $(grep_prop version $MODPATH/module.prop)"
ui_print "  VersionCode : $(grep_prop versionCode $MODPATH/module.prop)"

SDK=$(getprop ro.build.version.sdk)
ui_print "  SDK : $SDK (API)"
if [ "$SDK" -eq 31 ]; then
    sleep 1
    ui_print "  SDK version is supported. Continuing..."
else
    ui_print "  Android (SDK) version is not supported!"
    ui_print "  Module not installed!"
    ui_print ""
    exit 1
fi

ui_print ""
ui_print "• Search for DEEP_BUFFER Property:"
DBPROP=$(getprop audio.deep_buffer.media)
if [ -z "$DBPROP" ]; then
    sleep 2
    ui_print "  audio.deep_buffer.media property not found!"
    ui_print "  trying to force enable the property"
        resetprop -n audio.deep_buffer.media true
        sleep 3
    ui_print "  audio.deep_buffer.media is $(getprop audio.deep_buffer.media)"
else
    if [ "$DBPROP" == false ]; then
        resetprop -n audio.deep_buffer.media true
        sleep 2
    else
        ui_print "  audio.deep_buffer.media is $DBPROP"
    fi
fi

for CONFIG in $MODCONF; do
    DEEP_BUFFER=$(grep -c '<mixPort name="deep_buffer"' $CONFIG)
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

ui_print ""
ui_print "• Checking Sampling Rates:"
SAMPLERATE=$(grep 'samplingRates="44100 48000"' $MODCONF | sed -E 's/.*samplingRates="([^"]+)".*/\1/' | head -n 1)
    ui_print "  SamplingRates: $SAMPLERATE "
if [ "$SAMPLERATE" = "44100 48000" ]; then
    ui_print "- Enabling High Sampling Rates:"
    sleep 1
    sed -i 's|samplingRates="44100 48000"|samplingRates="44100 48000 96000 192000"|' $MODCONF
else
    ui_print "  ERROR! Device not using 44.1kHz/48kHz"
    ui_print ""
fi

HSR=$(grep 'samplingRates="44100 48000 96000 192000"' $MODCONF | sed -E 's/.*samplingRates="([^"]+)".*/\1/' | head -n 1)
    sleep 2
    ui_print "  SamplingRates: $HSR "
if [ "$HSR" = "44100 48000 96000 192000" ]; then
    sleep 1
    ui_print "  Success! device using High Sampling Rates."
fi

ui_print ""
ui_print "• Checking Dynamic Range Control (DRC):"
DRC=$(grep 'speaker_drc_enabled' $MODCONF | sed -E 's/.*speaker_drc_enabled="([^"]+)".*/\1/' | head -n 1)
if [ $DRC == false ]; then
    sleep 2
    ui_print "  DRC : $DRC "
    sleep 1
    ui_print "- Enabling Dynamic Range Control (DRC):"
    sed -i '/speaker_drc_enabled="false"/s/false/true/' $MODCONF
fi

DRCT=$(grep 'speaker_drc_enabled' $MODCONF | sed -E 's/.*speaker_drc_enabled="([^"]+)".*/\1/' | head -n 1)
if [ $DRCT == true ]; then
    sleep 2
    ui_print "  DRC : $DRCT "
    ui_print "  Success, DRC is Enabled!"
fi

ui_print ""
ui_print "• Checking GAIN value:"
GAIN=$(grep 'maxValueMB' $MODCONF | sed -E 's/.*maxValueMB="([^"]+)".*/\1/' | head -n 1)
if [ $GAIN == 4000 ]; then
    sleep 1
    ui_print "  GAIN : $GAIN "
    sleep 1
    ui_print "- Enabling Higher GAIN value:"
        sed -i '/maxValueMB="4000"/s/4000/8000/' $MODCONF
        sleep 3
fi

GAIND=$(grep 'maxValueMB' $MODCONF | sed -E 's/.*maxValueMB="([^"]+)".*/\1/' | head -n 1)
if [ $GAIND == 8000 ]; then
    sleep 2
    ui_print "  GAIN : $GAIND "
    ui_print "  Success!"
fi

ui_print ""
ui_print "• Checking FLAGS status:"
FLAGS=$(grep -A 5 'flags AUDIO_OUTPUT_FLAG_PRIMARY' $MODPOL | head -n 1)
if [[ -z "$FLAGS" ]]; then
    ui_print "  FLAG_PRIMARY not found! change to FLAG_DEEP_BUFFER"
    sleep 1
else
    ui_print "  status : $FLAGS"
    ui_print "- Enabling FLAG_DEEP_BUFFER:"
    sed -i 's|flags AUDIO_OUTPUT_FLAG_PRIMARY|flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER|' $MODPOL
    sleep 2
fi

FLAGD=$(grep -A 5 'flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER' $MODPOL | head -n 1)
if [[ -z $FLAGD ]]; then
    ui_print "  FLAG_DEEP_BUFFER not found!"
    sleep 1
else
    sleep 2
    ui_print "  status : $FLAGD"
    ui_print "  FLAG_DEEP_BUFFER is enabled!"
    ui_print "  Success!"
    ui_print ""
fi

ui_print " Patching to default Directory"
# Replace audio policy file (default)
REPLACE="
/system/vendor/etc/audio_policy.conf
"

for i in $REPLACE; do
    if [ -r "$i" ]; then
        chmod 644 "${MODPATH}${i}"
        chcon u:object_r:vendor_configs_file:s0 "${MODPATH}${i}"
        chown root:root "${MODPATH}${i}"
    fi
done

# Replace audio policy configuration file (default)
REPLACE="
/system/vendor/etc/audio_policy_configuration.xml
"

for i in $REPLACE; do
    if [ -r "$i" ]; then
        chmod 644 "${MODPATH}${i}"
        chcon u:object_r:vendor_configs_file:s0 "${MODPATH}${i}"
        chown root:root "${MODPATH}${i}"
    fi
done


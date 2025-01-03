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
if [ $SDK -eq 31 ]; then
    sleep 1
    ui_print "  SDK version is supported. Continuing..."
else
    ui_print "  Android (SDK) version is not supported!"
    ui_print "  Module not installed!"
    ui_print ""
    exit 1
fi

ui_print ""
ui_print " • Find deep_buffer property:"
DBPROP=$(getprop audio.deep_buffer.media)
if [ -z $DBPROP ]; then
    ui_print "  audio.deep_buffer.media property not found!"
    sleep 1
    ui_print " - trying to force enable the property:"
        resetprop -n audio.deep_buffer.media true
        sleep 2
    ui_print "   audio.deep_buffer.media is $(getprop audio.deep_buffer.media)"
else
    if [ $DBPROP == false ]; then
        resetprop -n audio.deep_buffer.media true
        sleep 2
        ui_print "   audio.deep_buffer.media is $(getprop audio.deep_buffer.media)"
    else
        ui_print "   audio.deep_buffer.media is $DBPROP"
    fi
fi


audio_policy() {
if [ "$(grep 'sampling_rates 44100|48000|96000|192000' $MODPOL | sed 's/sampling_rates//g; s/|/ /g' | sed 's/^ *//;s/ *$//' | head -n 1)" == "44100 48000 96000 192000" ]; then
    ui_print "   done!"
else
    ui_print "   failed!"
fi
}

ui_print ""
ui_print " • Checking Sampling_rates"
SAMPLINGRATE=$(grep 'sampling_rates 44100|48000|96000|192000' $MODPOL | sed 's/sampling_rates//g; s/|/ /g' | sed 's/^ *//;s/ *$//' | head -n 1)
if [ "$SAMPLINGRATE" == "44100 48000 96000 192000" ]; then
    sleep 2
    ui_print "   sampling_rates: $SAMPLINGRATE"
    sleep 1
    ui_print "   audio_policy using High Sampling Rates by default"
else
    sleep 1
    ui_print "   sampling_rates: $SAMPLINGRATE"
    sleep 1
    ui_print "   audio_policy not using High Sampling Rates by default"
    ui_print "   patching to audio_policy.conf"
    sed -i '/sampling_rates/{/96000\|192000/!s/44100\|48000/&\|96000\|192000/}' $MODPOL
    audio_policy
fi

touch $MODPATH/service.sh

{
  cat $MODPATH/service.sh
  echo "resetprop -n audio.deep_buffer.media true"
  echo ""
  echo "killall audioserver"
} > $MODPATH/service.sh

ui_print ""
ui_print " • Find deep_buffer mixport"
for CONFIG in $MODCONF; do
    DEEP_BUFFER=$(grep -c '<mixPort name="deep_buffer"' $CONFIG)
    sleep 1
    ui_print "   deep_buffer mixPort not found!"
    ui_print ""
    ui_print " - Patching new mixport:"
    if [ $DEEP_BUFFER -eq 0 ]; then
        sed -i '64a\
        <mixPort name="deep_buffer" role="source" flags="AUDIO_OUTPUT_FLAG_DEEP_BUFFER"> \
            <profile name="" format="AUDIO_FORMAT_PCM_32_BIT" \
                     samplingRates="44100 48000" channelMasks="AUDIO_CHANNEL_OUT_STEREO"/> \
            <profile name="" format="AUDIO_FORMAT_PCM_16_BIT" \
                     samplingRates="44100 48000" channelMasks="AUDIO_CHANNEL_OUT_STEREO"/> \
        </mixPort>' $CONFIG
    fi
    DBD=$(grep '<mixPort name="deep_buffer"' $CONFIG | sed -E 's/.*<mixPort name="([^"]+)".*/\1/' | head -n 1)
    if [ $DBD == "deep_buffer" ]; then
        sleep 2
        ui_print "   mixport: $DBD"
        sleep 1
        ui_print "   Success!"
    else
        ui_print "   Failed, add deep_buffer mixport!"
    fi
done
    
ui_print ""
ui_print " • Checking Sampling Rates"
SAMPLERATE=$(grep 'samplingRates="44100 48000"' $MODCONF | sed -E 's/.*samplingRates="([^"]+)".*/\1/' | head -n 1)
if [ "$SAMPLERATE" == "44100 48000" ]; then
    sleep 2
    ui_print "   SamplingRates: $SAMPLERATE "
    sleep 1
    ui_print ""
    ui_print " - Enabling High Sampling Rates"
    sed -i 's|samplingRates="44100 48000"|samplingRates="44100 48000 96000 192000"|' $MODCONF
    sleep 3
else
    ui_print "   ERROR! Device not using 44.1kHz/48kHz"
    ui_print ""
fi

HSR=$(grep 'samplingRates="44100 48000 96000 192000"' $MODCONF | sed -E 's/.*samplingRates="([^"]+)".*/\1/' | head -n 1)
if [[ "$HSR" == "44100 48000 96000 192000" ]]; then
    sleep 2
    ui_print "   SamplingRates: $HSR "
    sleep 1
    ui_print "   Device using High Sampling Rates (96kHz/192kHz)"
else
    ui_print "   Failed, device not using 96kHz/192kHz!"
fi

ui_print ""
ui_print " • Checking Dynamic Range Control (DRC)"
DRC=$(grep 'speaker_drc_enabled' $MODCONF | sed -E 's/.*speaker_drc_enabled="([^"]+)".*/\1/' | head -n 1)
if [ $DRC == false ]; then
    sleep 2
    ui_print "   DRC : $DRC "
    sleep 1
    ui_print ""
    ui_print " - Enabling Dynamic Range Control (DRC)"
    sed -i '/speaker_drc_enabled="false"/s/false/true/' $MODCONF
fi

DRCT=$(grep 'speaker_drc_enabled' $MODCONF | sed -E 's/.*speaker_drc_enabled="([^"]+)".*/\1/' | head -n 1)
if [ $DRCT == true ]; then
    sleep 2
    ui_print "   DRC : $DRCT "
    sleep 1
    ui_print "   DRC is Enabled!"
fi

ui_print ""
ui_print " • Checking GAIN value"
GAIN=$(grep 'maxValueMB' $MODCONF | sed -E 's/.*maxValueMB="([^"]+)".*/\1/' | head -n 1)
if [ $GAIN == 4000 ]; then
    ui_print "   GAIN : $GAIN "
    sleep 1
    ui_print ""
    ui_print " - Enabling Higher GAIN"
    sed -i '/maxValueMB="4000"/s/4000/8000/' $MODCONF
    sleep 2
fi

GAIND=$(grep 'maxValueMB' $MODCONF | sed -E 's/.*maxValueMB="([^"]+)".*/\1/' | head -n 1)
if [ $GAIND == 8000 ]; then
    sleep 1
    ui_print "   GAIN : $GAIND "
    sleep 1
    ui_print "   Custom GAIN enabled!"
fi

ui_print ""
ui_print " • Checking FLAGS status:"
FLAGS=$(grep -A 5 'flags AUDIO_OUTPUT_FLAG_PRIMARY' $MODPOL | sed -E 's/.*flags ([^ ]+).*/\1/' | head -n 1)
if [[ -z "$FLAGS" ]]; then
    ui_print "  FLAG_PRIMARY not found! change to FLAG_DEEP_BUFFER"
    sleep 1
else
    ui_print "   status : $FLAGS"
    sleep 1
    ui_print ""
    ui_print " - Enabling FLAG_DEEP_BUFFER"
    sed -i 's|flags AUDIO_OUTPUT_FLAG_PRIMARY|flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER|' $MODPOL
    sleep 2
fi

FLAGD=$(grep -A 5 'flags AUDIO_OUTPUT_FLAG_DEEP_BUFFER' $MODPOL | sed -E 's/.*flags ([^ ]+).*/\1/' | head -n 1)
if [[ -z $FLAGD ]]; then
    ui_print "   FLAG_DEEP_BUFFER not found!"
    sleep 1
else
    sleep 2
    ui_print "   status : $FLAGD"
    sleep 1
    ui_print "   FLAG_DEEP_BUFFER is enabled!"
fi

ui_print ""
ui_print "  Patching to default Directory:"
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

[ ! "$MODPATH" ] && MODPATH=${0%/*}
[ ! -d $MODPATH/system/vendor/etc ] && mkdir -p $MODPATH/system/vendor/etc

. $MODPATH/copy.sh

MODPOL=$(find $MODPATH -type f -name audio_policy.conf)
MODCONF=$(find $MODPATH -type f -name audio_policy_configuration.xml)
MODPARAM=$(find $MODPATH -type f -name Playback_ParamTreeView.xml)

aborting_sdk(){
    ui_print "  Android (SDK) version is not supported!"
    ui_print "  Module not installed!"
    abort "  Aborting process.."
}

aborting_platform(){
    ui_print "  this is not Mediatek Device!"
    ui_print "  Module not installed!"
    abort "  Aborting process.."
}

ui_print ""
ui_print "  Android version : $(getprop ro.build.version.release)"
ui_print "  Name : $(grep_prop name $MODPATH/module.prop)"
ui_print "  Version : $(grep_prop version $MODPATH/module.prop)"
ui_print "  VersionCode : $(grep_prop versionCode $MODPATH/module.prop)"
SDK=$API
ui_print "  SDK : $SDK (API)"
if [ $SDK == 31 ]; then
    sleep 1
    ui_print "  SDK version is supported. Continuing..."
elif [ $SDK -gt 31 ]; then
    sleep 1
    ui_print "  SDK version is supported. Continuing..."
elif [ $SDK -lt 31 ]; then
    sleep 1
    aborting_sdk
else
    sleep 1
    aborting_sdk
fi

platform=$(getprop ro.soc.manufacturer)
ui_print "  Platform : $platform"
if [ $platform ==  "Mediatek" ]; then
    sleep 1
    ui_print "  Device is Mediatek. Continuing..."
else
    aborting_platform
fi

createservice(){
    touch $MODPATH/service.sh
    {
        cat $MODPATH/service.sh
        echo "resetprop -n aaudio.mmap_policy 3"
        echo "resetprop -n aaudio.mmap_exclusive_policy 3"
        echo ""
        echo "killall audioserver"
    } > $MODPATH/service.sh
}

aaudio_mmap_properties(){
    ui_print ""
    ui_print " • Search for AAudio & MMAP Properties:"
    AMPPROP=$(getprop aaudio.mmap_policy)
    if [ -z $AMPPROP ]; then
        sleep 2
        ui_print "   aaudio.mmap_policy property not found!"
        ui_print "   trying to force add & enable the property"
            resetprop -n aaudio.mmap_policy 3
            sleep 3
        ui_print "   aaudio.mmap_policy is $(getprop aaudio.mmap_policy)"
    else
        if [ $AMPPROP == 3 ]; then
            ui_print "   aaudio.mmap_policy is $AMPPROP"
            ui_print "   success!"
        else
            ui_print "   aaudio.mmap_policy is $AMPPROP"
            ui_print "   set to '3' (1 = don't use, 2 = auto, 3 = always use) for MMAP"
            resetprop -n aaudio.mmap_policy 3
       fi
    fi

    AMEPPROP=$(getprop aaudio.mmap_exclusive_policy)
    if [ -z $AMEPPROP ]; then
        sleep 2
        ui_print ""
        ui_print "   aaudio.mmap_exclusive_policy property not found!"
        ui_print "   trying to force add & enable the property"
            resetprop -n aaudio.mmap_exclusive_policy 3
            sleep 3
        ui_print "   aaudio.mmap_exclusive_policy is $(getprop aaudio.mmap_exclusive_policy)"
        createservice
    else
        if [ $AMEPPROP == 3 ]; then
            ui_print "   aaudio.mmap_exclusive_policy is $AMEPPROP"
            ui_print "   success!"
        else
            ui_print "   aaudio.mmap_exclusive_policy is $AMEPPROP"
            ui_print "   set to '3' (1 = don't use, 2 = auto, 3 = always use) for MMAP"
            resetprop -n aaudio.mmap_exclusive_policy 3
            createservice
        fi
    fi
}

audio_policy_sampling_rates(){
    if [ "$(grep 'sampling_rates 44100|48000|96000|192000' $MODPOL | sed 's/sampling_rates//g; s/|/ /g' | sed 's/^ *//;s/ *$//' | head -n 1)" == "44100 48000 96000 192000" ]; then
        ui_print "   done!"
    else
        ui_print "   failed!"
    fi
}

audio_config_sampling_rates(){
    ui_print ""
    ui_print " • Checking Sampling Rates"
    SAMPLERATE=$(grep 'samplingRates="44100 48000"' $MODCONF | sed -E 's/.*samplingRates="([^"]+)".*/\1/' | head -n 1)
    if [ "$SAMPLERATE" == "44100 48000" ]; then
        sleep 2
        ui_print "   SamplingRates: $SAMPLERATE "
        sleep 1
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
}

aaudio_mmap_output(){
    POL=$(sed -n '/primary output/=;t' $MODCONF | head -n 1 | tr -d ' ')
    POLD=$(sed -n '/<mixPort name="primary output"/,/\/mixPort>/p' $MODCONF | wc -l)
    Z=1
    let VAL=POL+POLD-Z
    if [ "$VAL" -eq 64 ]; then
        sleep 3
        sed -i '64a\
                <mixPort name="mmap_no_irq_out" role="source" flags="AUDIO_OUTPUT_FLAG_MMAP_NOIRQ"> \
                    <profile name="" format="AUDIO_FORMAT_PCM_32_BIT" \
                             samplingRates="44100 48000" channelMasks="AUDIO_CHANNEL_OUT_ALL"/> \
                    <profile name="" format="AUDIO_FORMAT_PCM_16_BIT" \
                             samplingRates="44100 48000" channelMasks="AUDIO_CHANNEL_OUT_ALL"/> \
                </mixPort>' $MODCONF
        ui_print "   successful adding aaudio_mmap_output mixport!"
        sleep 1
    else
        ui_print "   error, can't patching mixport!"
    fi
}

aaudio_mmap_input(){
     PIL=$(sed -n '/primary input/=;t' $MODCONF | head -n 1 | tr -d ' ')
     PILD=$(sed -n '/<mixPort name="primary input"/,/\/mixPort>/p' $MODCONF | wc -l)
     Z=1
     let VOL=PIL+PILD-Z
     if [ "$VOL" -eq 85 ]; then
        sed -i '85a\
                <mixPort name="mmap_no_irq_in" role="sink" flags="AUDIO_INPUT_FLAG_MMAP_NOIRQ"> \
                    <profile name="" format="AUDIO_FORMAT_PCM_16_BIT" \
                             samplingRates="8000 16000 32000 44100 48000" \
                             channelMasks="AUDIO_CHANNEL_IN_MONO AUDIO_CHANNEL_IN_STEREO"/> \
                </mixPort>' $MODCONF
        ui_print "   successful adding aaudio_mmap_input mixport!"
    elif [ "$VOL" -eq 87 ]; then
        sed -i '87a\
                <mixPort name="mmap_no_irq_in" role="sink" flags="AUDIO_INPUT_FLAG_MMAP_NOIRQ"> \
                    <profile name="" format="AUDIO_FORMAT_PCM_16_BIT" \
                             samplingRates="8000 16000 32000 44100 48000" \
                             channelMasks="AUDIO_CHANNEL_IN_MONO AUDIO_CHANNEL_IN_STEREO"/> \
                </mixPort>' $MODCONF
        ui_print "   successful adding aaudio_mmap_input mixport!"
    elif [ "$VOL" -eq 91 ]; then
        sed -i '91a\
                <mixPort name="mmap_no_irq_in" role="sink" flags="AUDIO_INPUT_FLAG_MMAP_NOIRQ"> \
                    <profile name="" format="AUDIO_FORMAT_PCM_16_BIT" \
                             samplingRates="8000 16000 32000 44100 48000" \
                             channelMasks="AUDIO_CHANNEL_IN_MONO AUDIO_CHANNEL_IN_STEREO"/> \
                </mixPort>' $MODCONF
        ui_print "   successful adding aaudio_mmap_input mixport!"
    elif [ "$VOL" -eq 93 ]; then
        sed -i '93a\
                <mixPort name="mmap_no_irq_in" role="sink" flags="AUDIO_INPUT_FLAG_MMAP_NOIRQ"> \
                    <profile name="" format="AUDIO_FORMAT_PCM_16_BIT" \
                             samplingRates="8000 16000 32000 44100 48000" \
                             channelMasks="AUDIO_CHANNEL_IN_MONO AUDIO_CHANNEL_IN_STEREO"/> \
                </mixPort>' $MODCONF
        ui_print "   successful adding aaudio_mmap_input mixport!"
    elif [ "$VOL" -eq 99 ]; then
        sed -i '99a\
                <mixPort name="mmap_no_irq_in" role="sink" flags="AUDIO_INPUT_FLAG_MMAP_NOIRQ"> \
                    <profile name="" format="AUDIO_FORMAT_PCM_16_BIT" \
                             samplingRates="8000 16000 32000 44100 48000" \
                             channelMasks="AUDIO_CHANNEL_IN_MONO AUDIO_CHANNEL_IN_STEREO"/> \
                </mixPort>' $MODCONF
        ui_print "   successful adding aaudio_mmap_input mixport!"
    else
        ui_print "   error, can't patching mixport!"
    fi
}

ui_print ""
ui_print " • Find aaudio_mmap mixport:"
for CONFIG in $MODCONF; do
    AAUDIO_MMAP=$(grep -c '<mixPort name="mmap_no_irq_out"' $CONFIG)
    if [ $AAUDIO_MMAP -eq 0 ]; then
        sleep 1
        ui_print "   aaudio_mmap_output mixport not found!"
        ui_print " - Patching new mixport:"
        aaudio_mmap_output
    fi
    AAUDIO_MMAP_IN=$(grep -c '<mixPort name="mmap_no_irq_in"' $CONFIG)
    if [ $AAUDIO_MMAP -eq 0 ]; then
        sleep 2
        ui_print "   aaudio_mmap_input mixport not found!"
        sleep 1
        ui_print " - Patching new mixport:"
        aaudio_mmap_input
    fi
    AMOD=$(grep '<mixPort name="mmap_no_irq_out"' $CONFIG | sed -E 's/.*<mixPort name="([^"]+)".*/\1/' | head -n 1)
    if [ $AMOD == "mmap_no_irq_out" ]; then
        sleep 2
        ui_print "   mixport: $AMOD"
        sleep 1
        ui_print "   success!"
    else
        ui_print "   Failed to add aaudio_mmap_output mixport!"
    fi
    AMID=$(grep '<mixPort name="mmap_no_irq_in"' $CONFIG | sed -E 's/.*<mixPort name="([^"]+)".*/\1/' | head -n 1)
    if [ $AMID == "mmap_no_irq_in" ]; then
        sleep 2
        ui_print "   mixport: $AMID"
        sleep 1
        ui_print "   success!"
    else
        ui_print "   Failed to add aaudio_mmap_input mixport!"
    fi
done

aaudio_mmap_sources(){
    DBSRC=$(grep 'sources=".*deep_buffer.*"' $MODCONF | sed 's/.*sources="//;s/".*//;s/,/\n/g' | grep "deep_buffer" | head -n 1)
    if [ -z "$DBSRC" ]; then
        ui_print "   deep_buffer source not found! using primary for patching source.."
        ui_print "   source: $(grep 'sources=".*primary output.*"' $MODCONF | sed 's/.*sources="//;s/".*//;s/,/\n/g' | grep "primary output" | head -n 1)"
        sed -i '/sources=".*primary output/{s//&,mmap_no_irq_out/}' $MODCONF
    else
        ui_print "   source: $DBSRC"
        ui_print "   using deep_buffer for patching source!"
        sed -i '/sources=".*deep_buffer/{s//&,mmap_no_irq_out/}' $MODCONF
     fi
}

ui_print ""
ui_print " • Find source for AAudio & MMAP:"
SRC=$(grep 'sources=".*mmap_no_irq_out.*"' $MODCONF | sed 's/.*sources="//;s/".*//;s/,/\n/g' | grep "mmap_no_irq_out" | head -n 1)
if [ -z $SRC ]; then
    ui_print "   source not found!"
    ui_print "   adding source.."
    aaudio_mmap_sources
else
    ui_print "   source: $SRC"
fi

SRCD=$(grep 'sources=".*mmap_no_irq_out.*"' $MODCONF | sed 's/.*sources="//;s/".*//;s/,/\n/g' | grep "mmap_no_irq_out" | head -n 1)
if [ -z $SRCD ]; then
    ui_print "   source not found!"
    ui_print "   Failed, adding the source!"
else
    ui_print "   source: $SRCD"
    ui_print "   success!"
fi

source_in(){
    SRI=$(sed -n '/sink="primary input"/=;t' $MODCONF | head -n 1 | tr -d ' ')
    SRID=$(sed -n '/sink="primary input"/,/\/>/p' $MODCONF | wc -l)
    Z=1
    let VIL=SRI+SRID-Z
    if [ $VIL -eq 271 ]; then
        sed -i '271a\
                <route type="mix" sink="mmap_no_irq_in" \
                       sources="Built-In Mic,Built-In Back Mic,Wired Headset Mic"/>' $MODCONF
        ui_print "   successful adding source_in!"
    elif [ $VIL -eq 272 ]; then
        sed -i '272a\
                <route type="mix" sink="mmap_no_irq_in" \
                       sources="Built-In Mic,Built-In Back Mic,Wired Headset Mic"/>' $MODCONF
        ui_print "   successful adding source_in!"
    elif [ $VIL -eq 273 ]; then
        sed -i '273a\
                <route type="mix" sink="mmap_no_irq_in" \
                       sources="Built-In Mic,Built-In Back Mic,Wired Headset Mic"/>' $MODCONF
        ui_print "   successful adding source_in!"
    elif [ $VIL -eq 278 ]; then
        sed -i '278a\
                <route type="mix" sink="mmap_no_irq_in" \
                       sources="Built-In Mic,Built-In Back Mic,Wired Headset Mic"/>' $MODCONF
        ui_print "   successful adding source_in!"
    elif [ $VIL -eq 279 ]; then
        sed -i '279a\
                <route type="mix" sink="mmap_no_irq_in" \
                       sources="Built-In Mic,Built-In Back Mic,Wired Headset Mic"/>' $MODCONF
        ui_print "   successful adding source_in!"
    elif [ $VIL -eq 302 ]; then
        sed -i '302a\
                <route type="mix" sink="mmap_no_irq_in" \
                       sources="Built-In Mic,Built-In Back Mic,Wired Headset Mic"/>' $MODCONF
        ui_print "   successful adding source_in!"
    else
        ui_print "   error, can't patching source_in"
    fi
}

ui_print ""
ui_print " • Find source input for AAudio & MMAP"
AMIC=$(grep -c 'sink="mmap_no_irq_in"' $MODCONF)
if [ $AMIC -eq 0 ]; then
    ui_print "   source_in not found!"
    ui_print "   adding source_in.."
    sleep 2
    source_in
else
    ui_print "   source_in: $AMIC"
    ui_print "   success!"
fi

AMID=$(grep 'sink="mmap_no_irq_in"' $MODCONF | sed -E 's/.*sink="([^"]+)".*/\1/' | head -n 1)
if [ "$AMID" == "mmap_no_irq_in" ]; then
    ui_print "   source_in: $AMID"
    ui_print "   success!"
else
    ui_print "   Failed to add source_in!"    
fi

ui_print ""
ui_print " • Checking FLAGS status:"
FLAGS=$(grep -A 5 'flags AUDIO_OUTPUT_FLAG_PRIMARY' $MODPOL | sed -E 's/.*flags ([^ ]+).*/\1/' | head -n 1)
if [[ -z "$FLAGS" ]]; then
    ui_print "   FLAG_PRIMARY not found! change to FLAG_MMAP"
    sleep 1
else
    ui_print "   status : $FLAGS"
    sleep 1
    ui_print " - Enabling FLAG_MMAP"
    sed -i 's|flags AUDIO_OUTPUT_FLAG_PRIMARY|flags AUDIO_OUTPUT_FLAG_MMAP_NOIRQ|' $MODPOL
    sleep 2
fi

FLAGD=$(grep -A 5 'flags AUDIO_OUTPUT_FLAG_MMAP_NOIRQ' $MODPOL | sed -E 's/.*flags ([^ ]+).*/\1/' | head -n 1)
if [[ -z $FLAGD ]]; then
    ui_print "   FLAG_MMAP not found!"
    ui_print ""
    sleep 1
else
    sleep 2
    ui_print "   status : $FLAGD"
    sleep 1
    ui_print "   FLAG_MMAP is enabled!"
fi

aaudio_mmap_properties

ui_print ""
ui_print " • Checking Sampling_rates (Policy)"
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
    audio_policy_sampling_rates
fi

audio_config_sampling_rates

spkchannels(){
    SPKCH=$(grep -A 2 '<devicePort tagName="Speaker"' $MODCONF | sed -E 's/.*channelMasks="([^"]+)".*/\1/' | sed '/profile name=""/d' | sed '/devicePort/d' | sed '/samplingRates/d')
    if [ $SPKCH == "AUDIO_CHANNEL_OUT_STEREO" ]; then
        sleep 1
        ui_print "  - Enabling SURROUND for Speaker.. "
        sed -i '/<devicePort tagName="Speaker"/,/<\/devicePort>/ s/channelMasks="AUDIO_CHANNEL_OUT_STEREO"/channelMasks="AUDIO_CHANNEL_OUT_SURROUND"/g' "$MODCONF"
        sleep 3
    else
        sleep 1
        ui_print "    Speaker channel: $SPKCH"
        ui_print "    Speaker not use Stereo Channels"
    fi

    SPKCHV=$(grep -A 2 '<devicePort tagName="Speaker"' $MODCONF | sed -E 's/.*channelMasks="([^"]+)".*/\1/' | sed '/profile name=""/d' | sed '/devicePort/d' | sed '/samplingRates/d')
    if [ $SPKCHV == "AUDIO_CHANNEL_OUT_SURROUND" ]; then
        sleep 1
        ui_print "    Speaker channel: $SPKCHV"
        ui_print "    success!"
    else
        sleep 1
        ui_print "    failed!"
    fi
}

earchannels(){
    EARCH=$(grep -A 2 '<devicePort tagName="Earpiece"' $MODCONF | sed -E 's/.*channelMasks="([^"]+)".*/\1/' | sed '/profile name=""/d' | sed '/devicePort/d' | sed '/samplingRates/d')
    if [ $EARCH == "AUDIO_CHANNEL_OUT_MONO" ]; then
        sleep 1
        ui_print "  - Enabling STEREO for Earpiece.. "
        sed -i '/<devicePort tagName="Earpiece"/,/<\/devicePort>/ s/channelMasks="AUDIO_CHANNEL_OUT_MONO"/channelMasks="AUDIO_CHANNEL_OUT_STEREO"/g' $MODCONF
        sleep 3
    else
        sleep 1
        ui_print "    Earpiece Channel: $EARCH"
        ui_print "    Earpiece not use Mono Channel"
    fi

    EARCHV=$(grep -A 2 '<devicePort tagName="Earpiece"' $MODCONF | sed -E 's/.*channelMasks="([^"]+)".*/\1/' | sed '/profile name=""/d' | sed '/devicePort/d' | sed '/samplingRates/d')
    if [ $EARCHV == "AUDIO_CHANNEL_OUT_STEREO" ]; then
        sleep 1
        ui_print "    Earpiece channel: $EARCHV"
        ui_print "    success!"
    else
       sleep 1
       ui_print "    Earpiece channel: $EARCHV"
       ui_print "    failed!"
    fi
}

ui_print ""
ui_print " • Checking (Speaker) Channel status:"
CHSPK=$(grep -A 2 '<devicePort tagName="Speaker"' $MODCONF | sed -E 's/.*channelMasks="([^"]+)".*/\1/' | sed '/profile name=""/d' | sed '/devicePort/d' | sed '/samplingRates/d')
CHE=$(grep -A 2 '<devicePort tagName="Earpiece"' $MODCONF | sed -E 's/.*channelMasks="([^"]+)".*/\1/' | sed '/profile name=""/d' | sed '/devicePort/d' | sed '/samplingRates/d')
if [ $CHSPK == "AUDIO_CHANNEL_OUT_STEREO" ]; then
    if [ $CHE == "AUDIO_CHANNEL_OUT_MONO" ]; then
        ui_print "   Earpiece status: $CHE"
        ui_print "   (Speaker) status: $CHSPK"
        spkchannels
        earchannels
    else
        ui_print "   Earpiece status: $CHE (can't find Earpiece configuration!)"
        ui_print "   (Speaker) status: $CHSPK"
        ui_print "   only configure for Speaker channels.."
        spkchannels
    fi
else
    ui_print "   status: $CHSPK"
    ui_print "   Oops, channels is not Stereo!"
    ui_print "   can't patching with custom channels"
fi

channels_policy(){
    ui_print ""
    ui_print " • Checking Channels_Policy status:"
    CHP=$(grep -A 3 'outputs' $MODPOL | sed -E 's/.*channel_masks ([^ ]+).*/\1/' | sed '/sampling_rates/d' | sed '/outputs/d' | sed '/primary/d' | head -n 1)
    if [ $CHP == "AUDIO_CHANNEL_OUT_STEREO" ]; then
        ui_print "   status: $CHP"
        sleep 1
        ui_print " - Enabling custom channels (Policy)"
        sed -i '/outputs {/,/}/ { /primary {/,/}/ s/channel_masks AUDIO_CHANNEL_OUT_STEREO/channel_masks AUDIO_CHANNEL_OUT_ALL/ }' $MODPOL
        sed -i '/outputs {/,/}/ {/gain_1 {/,/}/ s/channel_mask AUDIO_CHANNEL_OUT_STEREO/channel_mask AUDIO_CHANNEL_OUT_ALL/ }' $MODPOL
        sleep 2
    else
        ui_print "   status: $CHP"
        ui_print "   Audio_Policy is not use STEREO by default"
        sleep 1
    fi
    VLDP=$(grep -A 3 'outputs' $MODPOL | sed -E 's/.*channel_masks ([^ ]+).*/\1/' | sed '/sampling_rates/d' | sed '/outputs/d' | sed '/primary/d' | head -n 1)
    VLDG=$(sed -n '/outputs {/,/}/ { /primary {/,/}/p }' $MODPOL | grep -A 2 'gain_1' | sed -E 's/.*channel_mask ([^ ]+).*/\1/' | sed '/mode/d' | sed '/gain_1/d' | head -n 1)
    if [ $VLDP == "AUDIO_CHANNEL_OUT_ALL" ]; then
        if [ $VLDG == "AUDIO_CHANNEL_OUT_ALL" ]; then
            ui_print "   status_output: $VLDP"
            ui_print "   status_gain: $VLDG"
            ui_print "   success, enabling custom channels!"
        else
            ui_print "   status: $VLDG (gain_1)"
            ui_print "   failed to set custom channels"
        fi
    else
        ui_print "   status: $VLDP (outputs)"
        ui_print "   failed to set custom channels!"
    fi
}

ui_print ""
ui_print " • Checking for Custom Channels_Policy:"
CHPP=$(grep -A 3 'outputs' $MODPOL | sed -E 's/.*channel_masks ([^ ]+).*/\1/' | sed '/sampling_rates/d' | sed '/outputs/d' | sed '/primary/d' | head -n 1)
CHPG=$(sed -n '/outputs {/,/}/ { /primary {/,/}/p }' $MODPOL | grep -A 2 'gain_1' | sed -E 's/.*channel_mask ([^ ]+).*/\1/' | sed '/mode/d' | sed '/gain_1/d' | head -n 1)
if [ $CHPP == "AUDIO_CHANNEL_OUT_STEREO" ]; then
    if [ $CHPG == "AUDIO_CHANNEL_OUT_STEREO" ]; then
        ui_print "   custom channels not configure!"
        ui_print "   patching custom channels in Policy.."
        channels_policy
        ui_print ""
        sleep 1
    else
        ui_print "   status: $CHPG (gain_1)"
        ui_print "   failed, can't find the channels_policy!"
        ui_print ""
    fi
else
    sleep 2
    ui_print "   status: $CHPP (outputs)"
    sleep 1
    ui_print "   failed, can't find channels_policy!"
    ui_print ""
fi

mainspeaker() {
    ui_print " - Configure (R) Speaker.."
    RACFSEP=$(grep '<Field audio_type="PlaybackACF" param="bes_loudness_Sep_LR_Filter"' $MODPARAM)
    if [ -z $RACFSEP ]; then
        sleep 1
        ui_print "   PlaybackACF Sep_LR Filter not found!"
        ui_print "   Failed to configure!"
    else
        ui_print "   PlaybackACF Sep_LR Filter found! deleting.."
        sed -i '/<Field audio_type="PlaybackACF" param="bes_loudness_Sep_LR_Filter"[^>]*>/d' $MODPARAM
    fi
    
    RACFSEPV=$(grep 'bes_loudness_Sep_LR_Filter' $MODPARAM)
    if [ -z $RACFSEPV ]; then
        sleep 1
        ui_print "   success!"
    else
        sleep 1
        ui_print "   failed!"
    fi
    
    RACFHPF=$(grep '<Field audio_type="PlaybackACF" param="bes_loudness_R_hpf_order"' $MODPARAM)
    if [ -z $RACFHPF ]; then
        sleep 1
        ui_print "   PlaybackACF HPF (High Pass Filter) not found!"
        ui_print "   Failed to configure!"
    else
        ui_print "   PlaybackACF HPF (High Pass Filter) found! deleting.."
        sed -i '/<Field audio_type="PlaybackACF" param="bes_loudness_R_hpf_order"[^>]*>/d' $MODPARAM
    fi
    
    RACFHPFV=$(grep 'bes_loudness_R_hpf_order' $MODPARAM | sed -n 's#.*param="# #p' | cut -d'"' -f1 | head -n 1)
    if [ -z $RACFHPFV ]; then
        sleep 1
        ui_print "   success!"
    else
        sleep 1
        ui_print "   failed!"
    fi
    
    RACFLPF=$(grep '<Field audio_type="PlaybackACF" param="bes_loudness_R_lpf_order"' $MODPARAM | sed -n 's#.*param="# #p' | cut -d'"' -f1 | head -n 1)
    if [ -z $RACFLPF ]; then
        sleep 1
        ui_print "   PlaybackACF LPF (Low Pass Filter) not found!"
        ui_print "   Failed to configure!"
    else
        ui_print "   PlaybackACF LPF (Low Pass Filter) found! configure.."
        sed -i 's/<Field audio_type="PlaybackACF" param="bes_loudness_R_lpf_order"[^>]*>/<Field audio_type="PlaybackACF" param="bes_loudness_R_lpf_order" name="2nd Loudspeaker Low Pass Filter Order"\/>/g' $MODPARAM
    fi
    
    RACFLPFV=$(grep 'bes_loudness_R_lpf_order' $MODPARAM | sed -n 's#.*param="# #p' | cut -d'"' -f1 | head -n 1)
    if [ -z $RACFLPFV ]; then
        sleep 1
        ui_print "   failed!"
    else
        sleep 1
        ui_print "   RLPF: $RACFLPFV"
        ui_print "   success!"
    fi
}

loudspeaker() {
    ui_print " - Configure (L) Speaker.."
    LACF=$(grep '<Field audio_type="PlaybackACF" param="bes_loudness_L_lpf_order"' $MODPARAM)
    if [ -z $LACF ]; then
        sleep 1
        ui_print "   PlaybackACF not found!"
        ui_print "   Failed to configure!"
    else
        ui_print "   PlaybackACF found! configure.."
        sed -i 's/<Field audio_type="PlaybackACF" param="bes_loudness_L_lpf_order"[^>]*>/<Field audio_type="PlaybackDRC" param="bes_loudness_Sep_LR_Filter" name="Apply Same Filter Setting with 2nd Loudspeaker\/>\n            <Field audio_type="PlaybackDRC" param="bes_loudness_L_bpf_gain" name="Band Pass Filter Gain">/g' $MODPARAM
    fi
    
    LACFV=$(grep 'bes_loudness_L_bpf_gain' $MODPARAM | sed -n 's#.*param="# #p' | cut -d'"' -f1 | head -n 1)
    if [ -z $LACFV ]; then
        sleep 1
        ui_print "   LBPF: $LACFV"
        ui_print "   failed!"
    else
        sleep 1
        ui_print "   LBPF: $LACFV"
        ui_print "   success!"
    fi
}

sleep 1
ui_print " • Find (R) Speaker configuration.."
SPKR=$(grep '<Feature name="2nd Loudspeaker Compensation Filter (2nd-ACF)"' $MODPARAM)
if [ -z $SPKR ]; then
    ui_print "   Oops, (R) Speaker configuration not found!"
    ui_print "   Failed, to change!"
else
    ui_print "   (R) Speaker configuration found!"
    sed -i 's/<Feature name="2nd Loudspeaker Compensation Filter (2nd-ACF)"[^>]*>/<Feature name="2nd Loudspeaker Compensation Filter (MOD-ACF)">/g' $MODPARAM
    sleep 1
    mainspeaker
fi

SPKRV=$(grep '<Feature name="2nd Loudspeaker Compensation Filter (MOD-ACF)">' $MODPARAM | sed -E 's/.*Feature name="([^"]+)".*/\1/' | cut -d'"' -f1 | head -n 1)
if [ "$SPKRV" == "2nd Loudspeaker Compensation Filter (MOD-ACF)" ]; then
    sleep 1
    ui_print " - MainSpeaker: $SPKRV"
    ui_print "   All (R) config, success!"
    ui_print ""
else
    sleep 1
    ui_print " - MainSpeaker: $SPKRV"
    ui_print "   All (R) config, failed!"
    ui_print ""
fi

sleep 1
ui_print " • Find (L) Speaker configuration.."
SPKL=$(grep '<Feature name="Loudspeaker Compensation Filter (ACF)">' $MODPARAM)
if [ -z $SPKL ]; then
    ui_print "   Oops, (L) Speaker configuration not found!"
    ui_print "   Failed, to change!"
else
    ui_print "   (L) Speaker configuration found!"
    sed -i 's/<Feature name="Loudspeaker Compensation Filter (ACF)">/<Feature name="Loudspeaker Dynamic Range Control (DRC)" switch_audio_type="PlaybackDRC" switch_param="bes_loudness_Sep_LR_Filter" switch_field="Apply Same Filter Setting with 2nd Loudspeaker">/g' $MODPARAM
    sleep 1
    loudspeaker
fi

SPKLV=$(grep 'Loudspeaker Dynamic Range Control (DRC)' $MODPARAM | sed -E 's/.*Feature name="([^"]+)".*/\1/' | cut -d'"' -f1 | head -n 1)
if [ "$SPKLV" == "Loudspeaker Dynamic Range Control (DRC)" ]; then
    sleep 1
    ui_print " - Earpiece: $SPKLV"
    ui_print "   All (L) config, success!"
    ui_print ""
else
    sleep 1
    ui_print " - Earpiece: $SPKLV"
    ui_print "   All (L) config, failed!"
    ui_print ""
fi

ui_print "  Patching to default Directory:"
APOL="/system/vendor/etc/audio_policy.conf"
for audiopolicy in $APOL; do
    if [ -r "$audiopolicy" ]; then
        chmod 644 "${MODPATH}${audiopolicy}"
        chcon u:object_r:vendor_configs_file:s0 "${MODPATH}${audiopolicy}"
        chown root:root "${MODPATH}${audiopolicy}"
    fi
done

ACONF="/system/vendor/etc/audio_policy_configuration.xml"
for audioconf in $ACONF; do
    if [ -r "$audioconf" ]; then
        chmod 644 "${MODPATH}${audioconf}"
        chcon u:object_r:vendor_configs_file:s0 "${MODPATH}${audioconf}"
        chown root:root "${MODPATH}${audioconf}"
    fi
done

DIRAP="/system/vendor/etc/*audio_param*/Playback_ParamTreeView.xml"
for playback in $DIRAP; do
    if [ -r "$playback" ]; then
        chmod 644 "${MODPATH}${playback}"
        chcon u:object_r:vendor_configs_file:s0 "${MODPATH}${playback}"
        chown root:root "${MODPATH}${playback}"
    fi
done

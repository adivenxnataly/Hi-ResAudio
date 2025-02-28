## Hi-Res Audio™
 ![](https://github.com/adivenxnataly/Hi-ResAudio/blob/main/files/banner.png)
 Enable **High-resolution** audio for MediaTek devices up to 32-bit/192kHz (if device supports).

> [!NOTE]
> this module only changes the configuration on `audio_policy` because most Android devices limit their capabilities to 16-bit/48kHz only, the rest depends on whether the device used supports Hi-Res Audio™ or not. <br>
> for Snapdragon user, u can use [this](https://github.com/reiryuki/Hi-Res-Audio-Enabler-Magisk-Module) from reiryuki.

 *applies to **internal Speakers & Wired** (not for Bluetooth/USB devices).
### Take note
  before install this module, try to get about what sampling rate is used on ur device, open terminal (adb, Termux, etc) with superuser `su` access, then enter the command:
  
      dumpsys media.audio_flinger

  look at the very top of the `"Output thread" (MIXER)` u will get information about:
  
   - Sample rate: `48000Hz` or `192000Hz`
   - Flags (AudioStreamOut): `AUDIO_OUTPUT_FLAG_PRIMARY` or `AUDIO_OUTPUT_FLAG_DEEP_BUFFER`
   - Format: `AUDIO_FORMAT_PCM_16_BIT` or `AUDIO_FORMAT_PCM_32_BIT`
 
![](https://github.com/adivenxnataly/Hi-ResAudio/blob/main/files/dumpsys-ss.jpg)

> or u can use "Sample Rate Checker" app:

![](https://github.com/adivenxnataly/Hi-ResAudio/blob/main/files/sampleratechecker.jpg)

> for testing the Hi-Res Audio using song with `24-bit/192kHz` & using USB Audio Player Pro (UAPP) app:
  
![](https://github.com/adivenxnataly/Hi-ResAudio/blob/main/files/usbaudioplayerpro.jpg)
> UAPP using `Variable rate` in Settings > Android audio > Android sample rate : Variable Rate (default is Fixed 44100 Hz)

The Result for v2.0 with AAudio & MMAP (using Device HW Info):
![](https://github.com/adivenxnataly/Hi-ResAudio/blob/main/files/aaudio_mmap.jpg)
> grant root access, then enter audio option

### Configurations
> [!NOTE]
>This configuration is what can be implemented on `audio_policy` which of course must be in accordance with the SDK version. i don't provide information for Android 11 and below, because this module is specifically for Android 12 and higher. if you are not satisfied with my module, you can modify it according to what i explained.

**Sampling Rate** : `44100`, `48000`, `88200`, `96000`, `192000`, `256000`, `384000`
<br>
**Format & Bit Depth** :
- `AUDIO_FORMAT_PCM_8_BIT`
- `AUDIO_FORMAT_PCM_16_BIT`
- `AUDIO_FORMAT_PCM_8_24_BIT`
- `AUDIO_FORMAT_PCM_24_BIT_PACKED`
- `AUDIO_FORMAT_PCM_32_BIT`
- `AUDIO_FORMAT_PCM_FLOAT`

>PCM is the standard output format, as it is a raw format and more flexible, rather than including formats that are specific to one particular format. for example, for MP3 we need to include `AUDIO_FORMAT_MP3`, likewise for other formats. this is not flexible therefore PCM is used as a universal output format.

**Flags** :
- `AUDIO_OUTPUT_FLAG_NONE`
- `AUDIO_OUTPUT_FLAG_DIRECT`
- `AUDIO_OUTPUT_FLAG_PRIMARY`
- `AUDIO_OUTPUT_FLAG_FAST`
- `AUDIO_OUTPUT_FLAG_DEEP_BUFFER`
- `AUDIO_OUTPUT_FLAG_COMPRESS_OFFLOAD`
- `AUDIO_OUTPUT_FLAG_NON_BLOCKING`
- `AUDIO_OUTPUT_FLAG_HW_AV_SYNC`
- `AUDIO_OUTPUT_FLAG_TTS`
- `AUDIO_OUTPUT_FLAG_RAW`
- `AUDIO_OUTPUT_FLAG_SYNC`
- `AUDIO_OUTPUT_FLAG_IEC958_NONAUDIO`
- `AUDIO_OUTPUT_FLAG_DIRECT_PCM`
- `AUDIO_OUTPUT_FLAG_MMAP_NOIRQ`
- `AUDIO_OUTPUT_FLAG_VOIP_RX`
- `AUDIO_OUTPUT_FLAG_INCALL_MUSIC`
- `AUDIO_OUTPUT_FLAG_GAPLESS_OFFLOAD` (Android 12)
- `AUDIO_OUTPUT_FLAG_SPATIALIZER` (Android 13)
- `AUDIO_OUTPUT_FLAG_ULTRASOUND` (Android 14)
- `AUDIO_OUTPUT_FLAG_BIT_PERFECT` (Android 15)
>Some Flags are only available on Android with the new SDK.

**Channels** :
- `AUDIO_CHANNEL_OUT_MONO` (front-left)
- `AUDIO_CHANNEL_OUT_STEREO` (front-left, front-right)
- `AUDIO_CHANNEL_OUT_2POINT1` (front-left, front-right, low-frequency)
- `AUDIO_CHANNEL_OUT_TRI` (front-left, front-right, front-center)
- `AUDIO_CHANNEL_OUT_TRI_BACK` (front-left, front-right, back-center)
- `AUDIO_CHANNEL_OUT_3POINT1` (front-left, front-right, front-center, low-frequency)
- `AUDIO_CHANNEL_OUT_2POINT0POINT2` (front-left, front-right, top-side-left, top-side-right)
- `AUDIO_CHANNEL_OUT_2POINT1POINT2` (front-left, front-right, top-side-left, top-side-right, low-frequency) 
- `AUDIO_CHANNEL_OUT_3POINT0POINT2` (front-left, front-right, front-center, top-side-left, top-side-right)
- `AUDIO_CHANNEL_OUT_3POINT1POINT2` (front-left, front-right, front-center, top-side-left, top-side-right, low-frequency)
- `AUDIO_CHANNEL_OUT_QUAD` (front-left, front-right, back-left, back-right)
- `AUDIO_CHANNEL_OUT_QUAD_SIDE` (front-left, front-right, side-left, side-right)
- `AUDIO_CHANNEL_OUT_SURROUND` (front-left, front-right, front-center, back-center)
- `AUDIO_CHANNEL_OUT_PENTA` (quad, front-center)
- `AUDIO_CHANNEL_OUT_5POINT1` (front-left, front-right, front-center, low-frequency, back-left, back-right)
- `AUDIO_CHANNEL_OUT_5POINT1_SIDE` (front-left, front-right, low-frequency, side-left, side-right)
- `AUDIO_CHANNEL_OUT_5POINT1POINT2` (5.1, side-left, side-right)
- `AUDIO_CHANNEL_OUT_5POINT1POINT4` (5.1, top-front-left, top-front-right, top-back-left, top-back-right)
- `AUDIO_CHANNEL_OUT_6POINT1` (front-left, front-right, front-center, low-frequency, back-left, back-right, back-center)
- `AUDIO_CHANNEL_OUT_7POINT1` (front-left, front-right, front-center, low-frequency, back-left, back-right, side-left, side-right)
- `AUDIO_CHANNEL_OUT_7POINT1POINT2` (7.1, top-side-left, top-side-right)
- `AUDIO_CHANNEL_OUT_7POINT1POINT4` (7.1, top-front-left, top-front-right, top-back-left, top-back-right)
- `AUDIO_CHANNEL_OUT_9POINT1POINT4` (7.1.4, front-wide-left, front-wide-right)
- `AUDIO_CHANNEL_OUT_9POINT1POINT6` (9.1.4, top-side-left, top-side-right)
- `AUDIO_CHANNEL_OUT_13POINT_360RA` (front-left, front-right, front-center, side-left, side-right, top-front-left, top-front-right, top-front-center, top-back-left, top-back-right, bottom-front-left, bottom-front-right, bottom-front-center)
- `AUDIO_CHANNEL_OUT_22POINT2` (7.1.4, front-left-of-center, front-right-of-center, back-center, top-center, top-front-center, top-back-center, top-side-left, top-side-right, bottom-front-left, bottom-front-right, bottom-front-center, low-frequency-2)
- `AUDIO_CHANNEL_OUT_MONO_HAPTIC_A` (mono, haptic-a)
- `AUDIO_CHANNEL_OUT_STEREO_HAPTIC_A` (stereo, haptic-a)
- `AUDIO_CHANNEL_OUT_HAPTIC_AB` (haptic-a, haptic-b)
- `AUDIO_CHANNEL_OUT_MONO_HAPTIC_AB` (mono, haptic-ab)
- `AUDIO_CHANNEL_OUT_STEREO_HAPTIC_AB` (stereo, haptoc-ab)
> this will not give a change in AudioFlinger level, only the `audio_policy` but still give an effect.

### Requirement
 this is module so install using Magisk app:
 [Download from Release page](https://github.com/adivenxnataly/Hi-ResAudio/releases)

  - Android 12 (SDK 31)
  - MTK devices
  
 **doesn't cause softbrick or bootloop.**
### Apps & Song

 - Device HW Info: [Here](https://play.google.com/store/apps/details?id=ru.andr7e.deviceinfohw)
 - Sample Rate Checker: [Here](https://drive.google.com/uc?export=download&id=12y7HTmKdsWJuvOrDS8F2VS-vdmJgE8Ow)
 - FLAC (24-bit/192kHz): [Download Song](https://drive.google.com/uc?export=download&id=1fI7vuuZyZ519OyzWF9x0rQD5qH7ZJlyd) 
 - USB Audio Player Pro (UAPP): [Here](https://play.google.com/store/apps/details?id=com.extreamsd.usbaudioplayerpro)

### Tested on (Stock ROM)
  - Android 12 - MIUI 13
  - Android 13 - MIUI 14
  - Android 14 - HyperOS 1.0

### etc.
**References:**
<br>
• [Audio Policy configuration](https://source.android.com/docs/core/audio/implement-policy)
<br>
• [AAudio & MMAP](https://source.android.com/docs/core/audio/aaudio)
<br>
• [Deep Buffer](https://android.googlesource.com/platform/frameworks/av/+/439e4ed)

**Sources:**
<br>
• [audio_policy.conf](https://dumps.tadiphone.dev/dumps/xiaomi/agate/-/blob/missi-user-12-SP1A.210812.016-V13.0.2.0.SKWMIXM-release-keys/vendor/etc/audio_policy.conf?ref_type=heads)
<br>
• [audio_policy_configuration.xml](https://dumps.tadiphone.dev/dumps/xiaomi/agate/-/blob/missi-user-12-SP1A.210812.016-V13.0.2.0.SKWMIXM-release-keys/vendor/etc/audio_policy_configuration.xml?ref_type=heads)
<br>
• [Playback_ParamTreeView.xml](https://dumps.tadiphone.dev/dumps/xiaomi/agate/-/blob/missi-user-12-SP1A.210812.016-V13.0.2.0.SKWMIXM-release-keys/vendor/etc/audio_param/Playback_ParamTreeView.xml?ref_type=heads)
<br>
• [Flags, Channels output & Format](https://cs.android.com/android/platform/superproject/+/main:system/media/audio/include/system/audio-hal-enums.h?hl=es-419)
<br>

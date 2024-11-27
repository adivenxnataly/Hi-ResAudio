## Hi-Res Audio™
 ![](https://github.com/adivenxnataly/Hi-ResAudio/blob/main/files/hires.png)
 Enable high resolution audio for MediaTek devices up to 32-bit/192kHz (if device supports).

 this module only changes the configuration on "audio_policy" because most Android devices limit their capabilities to 16-bit/48kHz only, the rest depends on whether the device used supports Hi-Res Audio™ or not.

 *applies to internal Speakers & Wired (not for Bluetooth/USB devices).
## Take note
  before you install this module, try to get about what sampling rate is used on your device, open terminal (adb, Termux, etc) with superuser `su` access, then enter the command:
  
      dumpsys media.audio_flinger

  look at the very top of the "Output thread" (MIXER):
  
  you will get information about the "Sample rate" used only "48000 Hz" or "192000 Hz", with the flags used such as: `AUDIO_OUTPUT_FLAG_PRIMARY` & `AUDIO_OUTPUT_FLAG_DEEP_BUFFER`, and what format to use: `AUDIO_FORMAT_PCM_16_BIT` or `AUDIO_FORMAT_PCM_32_BIT`

  *or u can use SampleRateChecker app.
## Requirement
 this is module so install using Magisk app:
 [Download from Release page](https://github.com/adivenxnataly/Hi-ResAudio/releases)

  - Android 12 (SDK 31)
  - MTK devices
  
 *does not cause softbrick or bootloop.

## Tested on (Stock ROM)
  - Android 12 - MIUI 13
  - Android 13 - MIUI 14
  - Android 14 - HyperOS 1.0

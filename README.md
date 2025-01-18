## Hi-Res Audio™
 ![](https://github.com/adivenxnataly/Hi-ResAudio/blob/main/files/banner.png)
 Enable High-resolution audio for MediaTek devices up to 32-bit/192kHz (if device supports).

> this module only changes the configuration on `audio_policy` because most Android devices limit their capabilities to 16-bit/48kHz only, the rest depends on whether the device used supports Hi-Res Audio™ or not.

 *applies to internal Speakers & Wired (not for Bluetooth/USB devices).
### Take note
  before you install this module, try to get about what sampling rate is used on your device, open terminal (adb, Termux, etc) with superuser `su` access, then enter the command:
  
      dumpsys media.audio_flinger

  look at the very top of the `"Output thread" (MIXER)` you will get information about:
  
   - Sample rate: `48000Hz` or `192000Hz`
   - Flags (AudioStreamOut): `AUDIO_OUTPUT_FLAG_PRIMARY` or `AUDIO_OUTPUT_FLAG_DEEP_BUFFER`
   - Format: `AUDIO_FORMAT_PCM_16_BIT` or `AUDIO_FORMAT_PCM_32_BIT`
 
![](https://github.com/adivenxnataly/Hi-ResAudio/blob/main/files/dumpsys-ss.jpg)

> or u can use "Sample Rate Checker" app:

![](https://github.com/adivenxnataly/Hi-ResAudio/blob/main/files/sampleratechecker.jpg)

> for testing the Hi-Res Audio using song with `24-bit/192kHz` & using USB Audio Player Pro (UAPP) app:
  
![](https://github.com/adivenxnataly/Hi-ResAudio/blob/main/files/usbaudioplayerpro.jpg)

### Requirement
 this is module so install using Magisk app:
 [Download from Release page](https://github.com/adivenxnataly/Hi-ResAudio/releases)

  - Android 12 (SDK 31)
  - MTK devices
  
 *does not cause softbrick or bootloop.
### Apps & Song

 - Sample Rate Checker: [Here](https://drive.google.com/uc?export=download&id=12y7HTmKdsWJuvOrDS8F2VS-vdmJgE8Ow)
 - FLAC (24-bit/192kHz): [Download Song](https://drive.google.com/uc?export=download&id=1fI7vuuZyZ519OyzWF9x0rQD5qH7ZJlyd) 
 - USB Audio Player Pro (UAPP): [Here](https://play.google.com/store/apps/details?id=com.extreamsd.usbaudioplayerpro)

### Tested on (Stock ROM)
  - Android 12 - MIUI 13
  - Android 13 - MIUI 14
  - Android 14 - HyperOS 1.0

**Changelog:**
   - using mmap_playback flags `AUDIO_OUTPUT_FLAG_MMAP_NOIRQ`
   - add mmap_input for low-latency input `AUDIO_INPUT_FLAG_MMAP_NOIRQ`
   - custom channels output with :
     > `AUDIO_CHANNEL_OUT_ALL` in `audio_policy.conf` to allow all types of channels, then for `audio_policy_configuration.xml` change from default `STEREO` for Speaker & `MONO` for Earpiece to `SURROUND` & `STEREO` with: `AUDIO_CHANNEL_OUT_SURROUND` & `AUDIO_CHANNEL_OUT_STEREO`
   - custom configurations for L/R Speaker with `Playback_ParamTreeView.xml`
   - disable custom GAIN
   - disable DRC (DynamicRangeControl)

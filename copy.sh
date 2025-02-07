[ ! "$MODPATH" ] && MODPATH=${0%/*}

copy_policy_file() {
  mkdir -p `dirname "$2"`
  cp -af "$1" "$2"
}

AUD="audio_policy.conf -o -name audio_policy_configuration.xml"
rm -f `find $MODPATH -type f -name $AUD`
FILES=$(find /vendor -type f -name $AUD)
for FILE in $FILES; do
  if [ -L $MODPATH/system/vendor ]\
  && [ -d $MODPATH/vendor ]; then
    MODFILE=$MODPATH$FILE
  else
    MODFILE=$MODPATH/system$FILE
  fi
  copy_policy_file $FILE $MODFILE
done

copy_param_file() {
  mkdir -p `dirname "$2"`
  cp -af "$1" "$2"
}

PARAM="Playback_ParamTreeView.xml"
rm -f `find $MODPATH -type f -name $PARAM`
FILEP=$(find /vendor -type f -name $PARAM)
for FILE in $FILEP; do
  if [ -L $MODPATH/system/vendor ]\
  && [ -d $MODPATH/vendor/etc ]; then
    MODFILE=$MODPATH$FILE
  else
    MODFILE=$MODPATH/system$FILE
  fi
  copy_param_file $FILE $MODFILE
done

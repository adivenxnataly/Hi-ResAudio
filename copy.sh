[ ! "$MODPATH" ] && MODPATH=${0%/*}

# function
copy_policy_file() {
  mkdir -p `dirname "$2"`
  cp -af "$1" "$2"
}

# audio file
AUD="audio_policy.conf -o -name audio_policy_configuration.xml"
rm -f `find $MODPATH -type f -name $AUD`
FILES=`find /system -type f -name $AUD`
for FILE in $FILES; do
  MODFILE=$MODPATH/system`echo "$FILE" | sed 's|/system||g'`
  copy_policy_file $FILE $MODFILE
done
FILES=`find /vendor -type f -name $AUD`
for FILE in $FILES; do
  if [ -L $MODPATH/system/vendor ]\
  && [ -d $MODPATH/vendor ]; then
    MODFILE=$MODPATH$FILE
  else
    MODFILE=$MODPATH/system$FILE
  fi
  

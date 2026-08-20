#!/bin/sh
LCD_BL=`/usr/trimui/bin/systemval brightness`
LCD_BL_SET=$LCD_BL

echo "get brightness:"$LCD_BL

if test $LCD_BL -lt 1; then
  LCD_BL_SET=2
  /usr/trimui/osd/show_info_msg.sh "Brightness 2/10"
elif test $LCD_BL -lt 3; then
  LCD_BL_SET=5
  /usr/trimui/osd/show_info_msg.sh "Brightness 5/10"
elif test $LCD_BL -lt 7; then
  LCD_BL_SET=10
  /usr/trimui/osd/show_info_msg.sh "Brightness 10/10"
else
  LCD_BL_SET=0
  /usr/trimui/osd/show_info_msg.sh "Brightness 0/10"
fi

echo "set brightness:"$LCD_BL_SET
echo -n $LCD_BL_SET > /tmp/system/set_brightness

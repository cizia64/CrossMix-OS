#!/bin/sh
echo "============= scene LEDC ============"

ledset=`/usr/trimui/bin/shmvar 10`
scale=`expr $ledset \* 4`
echo $scale


echo "==========================="
echo LED Brightness:$ledset
echo LED Scale:$scale
echo LED Enable:$leden

case "$1" in
0 ) 
        echo "disable LED"
	/usr/trimui/bin/shmvar 8 0
	echo -n 0 > /sys/class/led_anim/max_scale
        /usr/trimui/bin/systemval ledswitch 0
        ;;
1 )
        echo "resume LED"
	/usr/trimui/bin/shmvar 8 1
	echo -n $scale > /sys/class/led_anim/max_scale
        /usr/trimui/bin/systemval ledswitch 1                                                      
	;;
*)
        ;;
esac

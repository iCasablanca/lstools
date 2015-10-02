#!/bin/sh

### BEGIN INIT INFO
# Provides:          lsmonitor
# Required-Start:    $syslog
# Required-Stop:     $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Monitor Linkstation LS-WXL
# Description:       Enable service provided by daemon.
### END INIT INFO

#
# lsmonitor: 
# - handle ls complete power-on
# - monitor power switch
# - monitor hdd temperature & control fan speed
# - monitor function button (todo)
#
# blstools - Tools for Buffalo Linkstation
# Copyright (C) 2010 Michele Manzato
#
# Credits:
# 	Thanks to archonfx on Buffalo NAS Central forum for HDD 
#	temperature monitoring command.
#
# Changelog:
#	Modified to work with a Debian kernel on an LS-WXL 
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#

# Load settings
. /etc/default/lsmonitor

# Location of pid file
PIDFILE=/var/run/lsmonitor_daemon.pid

# GPIO's for LS-WXL
GPIO_PWR_SW=42			# Power switch (power switch)
GPIO_AUT_SW=43			# Auto-Power switch (auto switch)
GPIO_FAN_STAT=40		# Fan low speed enable (fan lock)
GPIO_FAN_LO=48			# Fan low speed enable (fan low)
GPIO_FAN_HI=47			# Fan high speed enable (fan high)

GPIO_POWER_HDD0=28		# (pmx-power-hdd0)
GPIO_POWER_HDD1=29		# (pmx-power-hdd1)
GPIO_USB_VBUS=37		# (pmx-usb-vbus)
GPIO_FAN_LOCK=40		# (pmx-fan-lock)
GPIO_FAN_HIGH=47		# (pmx-fan-high)
GPIO_FAN_LOW=48			# (pmx-fan-low)
GPIO_LED_HDDERR0=8		# (pmx-led-hdderr0)
GPIO_LED_HDDERR1=46		# (pmx-led-hdderr1)
GPIO_LED_ALARM=49		# (pmx-led-alarm)
GPIO_LED_FUNC_RED=34	# (pmx-led-func_red)
GPIO_LED_FUNC_BLUE=36	# (pmx-led-func_blue)
GPIO_LED_INFO=38		# (pmx-led-info)
GPIO_LED_POWER=39		# (pmx-led-power)
GPIO_BTN_FUNC=41		# (pmx-btn-func)
GPIO_POWER_SW=42		# (pmx-power-sw)
GPIO_POWER_AUTOSW=43	# (pmx-power-autosw)

gpio_config()
{
	if [ $1 == "enable" ]; then
		[ -d /sys/class/gpio/gpio$2 ] || echo $2 > /sys/class/gpio/export
		if [ $3 == "output" ]; then
			echo out > /sys/class/gpio/gpio$2/direction
		else
			echo in > /sys/class/gpio/gpio$2/direction
		fi
	else
		echo $2 > /sys/class/gpio/unexport
	fi
}

enable_gpio()
{
	gpio_config enable ${GPIO_PWR_SW} input
	gpio_config enable ${GPIO_AUT_SW} input
	gpio_config enable ${GPIO_FAN_STAT} input
	gpio_config enable ${GPIO_FAN_LO} output
	gpio_config enable ${GPIO_FAN_HI} output
}

disable_gpio()
{
	gpio_config disable ${GPIO_PWR_SW}
	gpio_config disable ${GPIO_AUT_SW}
	gpio_config disable ${GPIO_FAN_STAT}
	gpio_config disable ${GPIO_FAN_LO}
	gpio_config disable ${GPIO_FAN_HI}
}


# Monitor HDD temperature & control fan speed
monitor_temperature()
{
	HDDTEMP1=0
	HDDTEMP2=0
	
	# Retrieve HDD temp
	[ -b /dev/sda ] && HDDTEMP1=$(smartctl /dev/sda --all | awk '$1 == "194" {print $10}')
	[ -b /dev/sdb ] && HDDTEMP2=$(smartctl /dev/sdb --all | awk '$1 == "194" {print $10}')
	
	# Get max temp
	if [ $HDDTEMP1 -gt $HDDTEMP2 ]; then
		HDDTEMP=$HDDTEMP1
	else
		HDDTEMP=$HDDTEMP2
	fi

	# Change fan speed accordingly
	if [ $HDDTEMP -le $HDDTEMP0 ] ; then
		# off
		echo 1 > /sys/class/gpio/gpio${GPIO_FAN_LO}/value
		echo 1 > /sys/class/gpio/gpio${GPIO_FAN_HI}/value
	elif [ $HDDTEMP -le $HDDTEMP1 ] ; then
		# slow
		echo 0 > /sys/class/gpio/gpio${GPIO_FAN_LO}/value
		echo 1 > /sys/class/gpio/gpio${GPIO_FAN_HI}/value
	elif [ $HDDTEMP -le $HDDTEMP2 ] ; then
		# medium
		echo 1 > /sys/class/gpio/gpio${GPIO_FAN_LO}/value
		echo 0 > /sys/class/gpio/gpio${GPIO_FAN_HI}/value
	else
		# fast
		echo 0 > /sys/class/gpio/gpio${GPIO_FAN_LO}/value
		echo 0 > /sys/class/gpio/gpio${GPIO_FAN_HI}/value
	fi
}


# Control LS switch status to power down the unit
lsmonitor_daemon()
{
	COUNT=20
	while [ true ] ; do
		# Check switch status
		PWR_SW=`cat /sys/class/gpio/gpio${GPIO_PWR_SW}/value`
		AUT_SW=`cat /sys/class/gpio/gpio${GPIO_AUT_SW}/value`

		# Terminate when in OFF state
		if [ "$PWR_SW" -eq 1 ] && [ "$AUT_SW" -eq 1 ]; then
			break
		fi

		# Once per minute monitor HDD temperature
		if [ $COUNT -eq 20 ] ; then
			COUNT=0
			monitor_temperature
		else
			COUNT=$(( $COUNT + 1 ))
		fi

		sleep 3
		
	done

	# Run the fan at low speed while halting, just in case halt hangs the unit
	echo 0 > /sys/class/gpio/gpio${GPIO_FAN_LO}/value
	echo 1 > /sys/class/gpio/gpio${GPIO_FAN_HI}/value

	# blink power led
	echo timer > /sys/devices/platform/leds-gpio/leds/power/trigger
	echo   100 > /sys/devices/platform/leds-gpio/leds/power/delay_on
	echo   100 > /sys/devices/platform/leds-gpio/leds/power/delay_off
	
	# Initiate unit shutdown
	halt
}

# Kill the lsmonitor daemon
kill_lsmonitor_daemon()
{
        PID=`cat $PIDFILE`
	if [ "$PID" != "" ] ; then
        	kill $PID
		rm $PIDFILE
	fi
}


case $1 in
	start)
		# Enable the corresponding GPIO's
		enable_gpio
		
		# Start the lsmonitor daemon
		lsmonitor_daemon &
	        echo $! > $PIDFILE
  		;;
	stop)
		# Kill the lsmonitor daemon
		kill_lsmonitor_daemon

		# Disable the corresponding GPIO's
		disable_gpio
  		;;

	restart|force-reload)
		$0 stop && sleep 2 && $0 start
  		;;

	*)
		echo "Usage: $0 {start|stop|restart|force-reload}"
		exit 2
		;;
esac
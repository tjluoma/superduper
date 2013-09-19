#!/bin/sh
#
#	Author: Timothy J. Luoma
#	Email:	luomat at gmail dot com
#	Web:	
#	Date:	2008-02-29
#
#	Purpose: mount or unmount a drive
#		
#	NOTE: this script is meant to be placed in ~/bin/
# 		and the filename should begin with either "mount-" or "unmount-"
#		which dictates what action is taken
#	The idea is to name it something like 'mount-superduper-drive.sh'
#		and link it to 'unmount-superduper-drive.sh' so you can use it
#		as a shell script before-and-after running a scheduled SuperDuper
#		backup. This means that you do not have to have the drive
#		running all the time, screwing up Spotlight results, putting
#		extra wear and tear on the drive, etc.
#	It may have other uses as well.
#
# 	No promises/guarantees. Feel free to use/adapt/etc. 
#	Just ask for credit to remain

# HEY! DON'T FORGET TO EDIT THE 'DRIVE_NAME' LINE
# TO REFLECT WHAT IS RIGHT FOR YOUR COMPUTER.

	
	# Where Finder shows the drive when it is mounted
	DRIVE_NAME_SHORT="iMac_Backup"


# YOU SHOULD NOT *HAVE* TO EDIT ANYTHING BELOW THIS LINE
# However, if you find that the drive doesn't spin up fast enough
# You might want to increase TRIES (default is 3, shouldn't need more than 1)
TRIES=3




if [ $HOME/.source ]
then
	. $HOME/.source 
fi

# what action should it take?
# if the filename starts with mount- it will try to mount 
# if the filename starts with unmount- it will try to unmount
ACTION=`echo $0 | sed 's#.*/##g ;s#-.*##g'`

	
	# shown in 'mount' in Terminal.app when drive is mounted
	# DEVICE="/dev/disk6s2"
	# UNFORTUNATELY, this changes all the time
	# I would have made an entry in /etc/fstab
	# but OS X seems to want to not have anything to do with /etc/fstab
	#
	# Since this is a tool for OS X we don't have to worry
	# about portability, and 'diskutil list' will give us
	# what we need, with a little help
	
# run 'diskutil list' to get an idea of what we're dealing with
# But basically we look for the name we were given
# and the device will be the last iteme on the line
DEVICE_SHORT=`diskutil list | fgrep " $DRIVE_NAME_SHORT " | awk '{print $NF}'`

if [ "$?" != "0" ]
then

		echo "
		$NAME: Sorry, I could not find $DRIVE_NAME_SHORT in 'diskutil list'.
		Please check to make sure the drive is physically connected 
			and that it is usually called $DRIVE_NAME_SHORT

		You may want to check /Applications/Utilities/Disk Utility.app
		"

		exit 1
fi

# Stick /Volumes/ in front of whatever name we were given
DRIVE_NAME="/Volumes/$DRIVE_NAME_SHORT"

# Stick /dev/ in front of whatever we got for the device
DEVICE="/dev/$DEVICE_SHORT"


# initialize a counter, we use this to check if we've exceeded $TRIES
COUNT=1

if [ "$ACTION" = "mount" -o "$ACTION" = "unmount" ]
then
	# OK, well the filename is named correctly, beginning either with mount- or unmount-


	if [ "$ACTION" = "mount" ]
	then
		# We're going to mount a drive that isn't mounted
		
	
		if [ -d "$DRIVE_NAME" ]
		then
			# Check to see if the drive already appears to be mounted
			# If so, exit quietly
			echo "$0: Drive is already mounted at $DRIVE_NAME"
			exit 0
			
		else
		
			# If we get here, the drive is not mounted
		
			# We're going to loop this
			# although it SHOULD work on the first try
			while [ "$COUNT" -le "$TRIES" ]
			do
			
				# 'diskutil' doesn't require sudo
				# So we run it and see how it exits
				diskutil mount "$DEVICE" 2>/dev/null
				DISKUTIL_EXIT="$?"
				
				
				if [ "$DISKUTIL_EXIT" = "0" ]
				then
					# success! Drive mounted
					# Exit quickly and quietly
					exit 0
				else
					
					# Ok, it didn't seem to work
					# Increment the counter
					COUNT=`expr $COUNT + 1`
					
					# give the drive a few extra seconds
					# in case it is just spinning up slowly.
					sleep 2 
				fi	
			
			done # WHILE LOOP for TRIES

			# if we get here it means we exceeded $TRIES
			# without mounting drive
			# yell for help
			
			echo "$0: Unable to mount $DEVICE to $DRIVE_NAME after $TRIES tries"
			exit 2
			
		fi	# if drive is not already mounted
	
	else
		# Action is unmount
		
		if [ -d "$DRIVE_NAME" ]
		then

			# If we get here, there is a folder at $DRIVE_NAME, so let's try to unmount it

		
			while [ "$COUNT" -le "$TRIES" ]
			do
				# Again, diskutil doesn't require sudo			
				diskutil eject "$DRIVE_NAME" 2>/dev/null
			
				# Check how it exited
				DISKUTIL_EXIT="$?"
				
				if [ "$DISKUTIL_EXIT" = "0" ]
				then
					# success! Get out now
					exit 0
				else
					# Did not unmount
					COUNT=`expr $COUNT + 1`
					sleep 2 # give it a chance just in case it went slow
				fi	
			
			done

			# if we get here it means we exceeded $TRIES
			# without unmounting drive
			# yell for help
			
			echo "
			$0: Unable to unmount $DEVICE from $DRIVE_NAME after $TRIES tries
			This probably means there is a file open on $DRIVE_NAME which is being used
			by some application, or perhaps Spotlight. Sorry.
			"
			exit 2

		else
			# If we get here, they asked us to unmount a drive we can't find in the first place
			echo "$0: Drive is not mounted at $DRIVE_NAME"
			
			# Still, the end result is what they wanted, no drive mounted at $DRIVE_NAME
			# so we exit cleanly
			exit 0
		fi	
	
	fi	# if action = mount (unmount is 'else' clause)
	
	
else

	# If we get here, they didn't listen to the instructions as to how to name the file

	echo "$0: I don't know what to do if my filename doesn't begin with either mount- or unmount-"
	
	exit 1

fi

# That's all, folks
exit 0


# EOF
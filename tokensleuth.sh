#!/bin/bash

#############################################################################################
#
# Copyright (c) 2020, JAMF Software, LLC. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without # modification, are permitted provided that the following conditions are met:
# * Redistributions of source code must retain the above copyright # notice, this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright # notice, this list of conditions and the following disclaimer in the # documentation and/or other materials provided with the distribution.
# * Neither the name of the JAMF Software, LLC nor the # names of its contributors may be used to endorse or promote products # derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY # EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED # WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE # DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY # DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES # (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; # LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND # ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT # (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS # SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
###############
# Ginger Zosel 
# July 2021
#
# This script helps identify the 'clientContext' (the server or process that "owns" a VPP token)
# to help in situations where we are seeing a 'reclaim' button and are not sure why
#
# This can also be used for basic VPP troubleshooting to ensure that the client context is correct
# in situations where licenses aren't assigning as expected 
#
#############################################################################################r


###############
# Functions
########


requestVPPtoken () {
echo "then hit Enter to proceed"
read "tokenpath"
token=$(cat "$tokenpath")
}

invalidtoken () {
	echo
	echo "**************************"
	echo "! No valid token found !"
	echo "**************************"
}

reportclientcontext () {
	clientcontext=$(echo $response | sed 's/.*hostname....//' | sed 's/}.*//'| sed 's/\\//g' )
	echo 
	echo
	echo "This VPP token is currently associated with ${bold} $clientcontext ${normal} "
	echo
	echo "If this does not match your Jamf URL, please ensure that the token is removed from the other location"
	echo "Then reclaim the token in your Jamf instance"
	echo "If this does match your url, and you are still seeing a reclaim button"
	echo "please ensure that the same VPP token has not been uploaded as two entries"
}

###############
# Formatting Variables
####

bold=$(tput bold)
normal=$(tput sgr0)

###############
# Text Intro
########

echo
echo
echo "Please drag and drop the VPP token into the Terminal window"
requestVPPtoken

###############
# Logic
########

if [ -z "$token" ]
then 
	invalidtoken
	echo "Please ensure there are no special characters or spaces in the file path and try again"
	requestVPPtoken
else

# get information on the VPP token
response=$(curl -s --location --request POST "https://vpp.itunes.apple.com/mdm/VPPClientConfigSrv?verbose=true&sToken=$token" )
# check to make sure that we didn't receive a response indicating that the token is invalid
responsevalidation=$( echo $response | grep -o "Invalid authentication token")

	if [ -n "$responsevalidation" ]
	then 
		invalidtoken
			echo "Please ensure that this is a valid VPP token file"
		requestVPPtoken
	fi
fi

# Check for hostname in vpp response as an indicator of client context
association=$( echo $response | grep -o hostname  )

# If no hostname is reported, inform of that there is no registered client context
if [ -z $association ]
then
	echo "This VPP token is not associated with any clientContext or server"

# If a host name is reported, return along with client context for next troubleshooting steps
else
	reportclientcontext
fi



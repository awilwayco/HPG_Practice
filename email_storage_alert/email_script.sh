#!/bin/bash

# ===== Email Alert about User Quota Usage ===== #
# Closes Ticket #58240

# Functions #

# Bold Text
bold() {
  echo "<b>$1</b>"
}

# Underline Text
underline() {
  echo "<u>$1</u>"
}

# Bold and Underline Text
bold_underline() {
  local bold_text=$(bold "$1")  # Calling the 'bold()' function
  local bold_underline_text=$(underline "$bold_text")  # Calling the 'underline()' function
  echo "$bold_underline_text"
}

# Calculate percentage based on used and quota values
calculate_home_percentage() {
  local command=$1

  # Run the specified command and capture the output
  local quota_output=$($command)

  # Extract the used and quota values using awk
  local used=$(echo "$quota_output" | awk 'NR==3{print $2}')
  local quota=$(echo "$quota_output" | awk 'NR==3{print $1}')

  # Remove 'G' suffix from used and quota
  used=${used%G}
  quota=${quota%G}

  # Perform the division and calculate the percentage with two decimal places
  local percentage=$(awk "BEGIN {printf \"%.2f\", $used / $quota * 100}")

  # Return the percentage value
  echo "$percentage"
}

# Storage Quotas #

# Home Quota
home_message=$(bold_underline "Home Quota")
home=$(echo "$(home_quota 2>/dev/null)" | sed '$d')
if [ -z "$home" ]; then
    home="No Home Storage Available"
else
    home_per=$(echo "Percentage Used: $(calculate_home_percentage "home_quota")%")
fi

# Blue Quota
blue_message=$(bold_underline "Blue Quota")
blue=$(echo "$(blue_quota 2>/dev/null)" | sed '$d')
if [ -z "$blue" ]; then
    blue="No Blue Storage Available"
fi

# Orange Quota
orange_message=$(bold_underline "Orange Quota")
orange=$(echo "$(orange_quota 2>/dev/null)" | sed '$d')
if [ -z "$orange" ]; then
    orange="No Orange Storage Available"
fi

# Total Storage with Messages
total_storage="$home_message\n$home\n$home_per\n\n$blue_message\n$blue\n\n$orange_message\n$orange"

# Email details
#sender="support"
sender="awilwayco@ufl.edu"
recipient="awilwayco@ufl.edu"
subject="HiPerGator Storage at Critical Levels"
#body="<html><body><p>$home_message</p></body></html>$home"
body=$(printf "<pre>%s</pre>" "$total_storage")

# Send the email
echo -e "Subject: $subject\nFrom: $sender\nTo: $recipient\nContent-Type: text/html\n$body" | sendmail -t


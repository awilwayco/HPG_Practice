#!/bin/bash

# ===== Email Alert about User Quota Usage ===== #
# Closes Ticket #58240

# Global flag variables
declare -g enable_flag=false
declare -g disable_flag=false
declare -g send_flag=false

flags() {

  # Trap Ctrl+C signal (SIGINT)
  trap ctrl_c INT

  # Function to handle Ctrl+C signal
  function ctrl_c() {
    echo -e "\nExiting..."
    exit 1
  }

  # Default values for the flags
  help_flag=false

  # Process command line options
  while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
      -s|--send)
        send_flag=true
        shift
        ;;
      -e|--enable)
        enable_flag=true
        shift
        ;;
      -d|--disable)
        disable_flag=true
        shift
        ;;
      -h|--help)
        help_flag=true
        shift
        ;;
      *)
        echo "Invalid option: $key" >&2
        exit 1
        ;;
    esac
  done

  # Display help message if help flag is set
  if [ "$help_flag" = true ]; then
    echo -e ""
    echo "Usage: esa [options]"
    echo -e ""
    echo "Description: Email Alert Service for HiPerGator Storage"
    echo -e ""
    echo "Options:"
    echo "  -e, --enable   Enable email service"
    echo "  -d, --disable  Disable email service"
    echo "  -s, --send     Send email manually"
    echo "  -h, --help     Show help message"
    echo -e ""
    exit 0
  fi

  # Access the value of the send flag
  if [ "$send_flag" = true ]; then
    echo "Sending email..."
    # Load Necessary Modules
    ml purge
    ml ufrc
  fi

  # Access the value of the enable flag
  if [ "$enable_flag" = true ]; then
    echo "Enabling email service..."
    # Add the lines to ~/.bashrc if they don't exist
    if ! grep -q "# Email Storage Alert Service Enabled" ~/.bashrc; then
      echo '# Email Storage Alert Service Enabled' >> ~/.bashrc
      echo 'alias esa=/apps/email_storage_alert/bin/./esa' >> ~/.bashrc
      echo '( esa & )' >> ~/.bashrc
    fi
    exit 0
  fi

  # Access the value of the disable flag
  if [ "$disable_flag" = true ]; then
    echo "Disabling email service..."
    # Remove the lines from ~/.bashrc if they exist
    if grep -q "# Email Storage Alert Service Enabled" ~/.bashrc; then
      sed -i '/# Email Storage Alert Service Enabled/d' ~/.bashrc
      sed -i '/alias esa=\/apps\/email_storage_alert\/bin\/.\/esa/d' ~/.bashrc
      sed -i '/( esa & )/d' ~/.bashrc
    fi
    exit 0
  fi
}

# Check Flags
flags "$@"

# Global Variables
# Storage Critical Checks
declare -g homeStorageCritical=false
declare -g blueStorageCritical=false
declare -g orangeStorageCritical=false

# Green Checkmark
green_checkmark="&#10004;"  # HTML entity for checkmark symbol
green_checkmark_html="<span style=\"color: green; font-size: 16px;\">$green_checkmark</span>" # Generate HTML code snippet

# Red X
red_x="&#10060;"  # HTML entity for X symbol
red_x_html="<span style=\"color: red; font-size: 12px;\">$red_x</span>"

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

make_percent_bar() {
    local storage_percentage="$1"
    local progress_color="$2"

    if (( $(echo "$storage_percentage >= 90.00" | bc -l) )); then
        progress_color="#D00000"  # Red color as default if not specified
    fi

    local class_name="progress-bar-$(date +%s%N)"
    local css_style=".${class_name} .progress-bar{width:250px;height:16px;border-radius:8px;overflow:hidden;position:relative;}.${class_name} .progress-bar-fill{height:100%;background-color:#E8E8E8;border-radius:8px;position:relative;}.${class_name} .progress-bar-fill-inner{height:100%;background-color:${progress_color};border-radius:8px;width:${storage_percentage}%;position:relative;}.${class_name} .progress-bar-percent{position:absolute;top:0;left:0;width:100%;height:100%;display:flex;justify-content:center;align-items:center;font-weight:bold;color:#000000;}"

    local html_content="<div class=\"${class_name}\"><style>${css_style}</style><div class=\"progress-bar\"><div class=\"progress-bar-fill\"><div class=\"progress-bar-fill-inner\"></div><div class=\"progress-bar-percent\">${storage_percentage}%</div></div></div></div>"

    echo "$html_content"
}

# Calculate percentage based on used and quota values
calculate_home_percentage() {

  # Run the specified command and capture the output
  local quota_output=$(home_quota)

  # Extract the used and quota values using awk
  local used=$(echo "$quota_output" | awk 'NR==3{print $2}')
  local quota=$(echo "$quota_output" | awk 'NR==3{print $1}')

  # Convert to Gigabytes

  # Extract the numerical part of the variables
  local used_value="${used%[A-Z]*}"
  local quota_value="${quota%[A-Z]*}"

  # Determine the unit (T or G) for each variable
  local used_unit="${used: -1}"
  local quota_unit="${quota: -1}"

  # Convert everything to Terabytes
  if [ "$used_unit" = "k" ]; then
    used_value=$(echo "scale=40; $used_value / 1024" | bc)
    used_value=$(echo "scale=40; $used_value / 1024" | bc)
  fi

  if [ "$quota_unit" = "k" ]; then
    quota_value=$(echo "scale=40; $quota_value / 1024" | bc)
    quota_value=$(echo "scale=40; $quota_value / 1024" | bc)
  fi

  if [ "$used_unit" = "M" ]; then
    used_value=$(echo "scale=20; $used_value / 1024" | bc)
  fi

  if [ "$quota_unit" = "M" ]; then
    quota_value=$(echo "scale=20; $quota_value / 1024" | bc)
  fi

  # Perform the division and calculate the percentage with two decimal places
  home_percentage=$(awk "BEGIN {printf \"%.2f\", $used_value / $quota_value * 100}")

  # Return the percentage value
  if [ "$home_percentage" = "0.00" ]; then
    echo "\nPercentage Used: <0.01%"
  else
    echo "\nPercentage Used: $home_percentage%"
  fi

  # Make Home Percent Bar
  local home_bar=$(make_percent_bar "$home_percentage" "#046a38")
  echo "\n$home_bar"

  # Check if Home Storage is Critical
  if (( $(awk -v p="$home_percentage" 'BEGIN { if (p >= 90.00) print 1; else print 0; }') )); then
    echo "Status: $red_x_html"
    echo "Note: Home Storage Critical. Please clear up your home directory."
    homeStorageCritical=true
  else
    echo "Status: $green_checkmark_html"
    echo "Note: Home Storage Under 90%"
  fi
}

calculate_blue_percentage() {
    # Run the blue_quota command and capture the output
    local quota_output=$(blue_quota)

    # Extract group used and quota values
    local group_used=$(echo "$quota_output" | awk 'NR==3{print $2}')
    local group_quota=$(echo "$quota_output" | awk 'NR==3{print $3}')
    local user_used=$(echo "$quota_output" | awk 'NR==6{print $2}')

    # Extract the numerical part of the variables
    local group_used_value="${group_used%[A-Z]*}"
    local group_quota_value="${group_quota%[A-Z]*}"
    local user_used_value="${user_used%[A-Z]*}"

    # Determine the unit (T or G) for each variable
    local group_used_unit="${group_used: -1}"
    local group_quota_unit="${group_quota: -1}"
    local user_used_unit="${user_used: -1}"

    # Convert everything to Terabytes
    if [ "$group_used_unit" = "k" ]; then
        group_used_value=$(echo "scale=40; $group_used_value / 1024" | bc)
        group_used_value=$(echo "scale=40; $group_used_value / 1024" | bc)
        group_used_value=$(echo "scale=40; $group_used_value / 1024" | bc)
    fi

    if [ "$group_quota_unit" = "k" ]; then
        group_quota_value=$(echo "scale=40; $group_quota_value / 1024" | bc)
        group_quota_value=$(echo "scale=40; $group_quota_value / 1024" | bc)
        group_quota_value=$(echo "scale=40; $group_quota_value / 1024" | bc)
    fi

    if [ "$user_used_unit" = "k" ]; then
        user_used_value=$(echo "scale=40; $user_used_value / 1024" | bc)
        user_used_value=$(echo "scale=40; $user_used_value / 1024" | bc)
        user_used_value=$(echo "scale=40; $user_used_value / 1024" | bc)
    fi

    if [ "$group_used_unit" = "M" ]; then
        group_used_value=$(echo "scale=20; $group_used_value / 1024" | bc)
        group_used_value=$(echo "scale=20; $group_used_value / 1024" | bc)
    fi

    if [ "$group_quota_unit" = "M" ]; then
        group_quota_value=$(echo "scale=20; $group_quota_value / 1024" | bc)
        group_quota_value=$(echo "scale=20; $group_quota_value / 1024" | bc)
    fi

    if [ "$user_used_unit" = "M" ]; then
        user_used_value=$(echo "scale=20; $user_used_value / 1024" | bc)
        user_used_value=$(echo "scale=20; $user_used_value / 1024" | bc)
    fi

    if [ "$group_used_unit" = "G" ]; then
        group_used_value=$(echo "scale=10; $group_used_value / 1024" | bc)
    fi

    if [ "$group_quota_unit" = "G" ]; then
        group_quota_value=$(echo "scale=10; $group_quota_value / 1024" | bc)
    fi

    if [ "$user_used_unit" = "G" ]; then
        user_used_value=$(echo "scale=10; $user_used_value / 1024" | bc)
    fi

    # Calculate percentages
    local blue_group_percentage=$(awk "BEGIN {printf \"%.2f\", $group_used_value / $group_quota_value * 100}")
    local blue_user_percentage=$(awk "BEGIN {printf \"%.2f\", $user_used_value / $group_quota_value * 100}")

    # Return the percentage values
    if [ "$blue_group_percentage" = "0.00" ]; then
        echo "\nTotal Used Percentage of Group: <0.01%"
    else
        echo "\nTotal Used Percentage of Group: $blue_group_percentage%"
    fi

    # Make Blue Group Percent Bar
    local blue_group_bar=$(make_percent_bar "$blue_group_percentage" "#0021A5")
    echo "\n$blue_group_bar"

    if [ "$blue_user_percentage" = "0.00" ]; then
        echo "Personal Use Percentage of Group: <0.01%"
    else
        echo "Personal Use Percentage of Group: $blue_user_percentage%"
    fi

    # Make Blue User Percent Bar
    local blue_user_bar=$(make_percent_bar "$blue_user_percentage" "#0021A5")
    echo "\n$blue_user_bar"

    # Check if Blue Storage is Critical
    if (( $(awk -v p="$blue_group_percentage" 'BEGIN { if (p >= 90.00) print 1; else print 0; }') )); then
      echo "Status: $red_x_html"
      echo "Note: Blue Group Storage Critical. Please clear up your group's blue directory."
    else
      echo "Status: $green_checkmark_html"
      echo "Note: Blue Storage Under 90%"
    fi

}

calculate_orange_percentage() {
    # Run the blue_quota command and capture the output
    local quota_output=$(orange_quota)

    # Extract group used and quota values
    local group_used=$(echo "$quota_output" | awk 'NR==4{print $2}')
    local group_quota=$(echo "$quota_output" | awk 'NR==4{print $3}')
    local user_used=$(echo "$quota_output" | awk 'NR==8{print $2}')

    # Extract the numerical part of the variables
    local group_used_value="${group_used%[A-Z]*}"
    local group_quota_value="${group_quota%[A-Z]*}"
    local user_used_value="${user_used%[A-Z]*}"

    # Determine the unit (T or G) for each variable
    local group_used_unit="${group_used: -1}"
    local group_quota_unit="${group_quota: -1}"
    local user_used_unit="${user_used: -1}"

    # Convert everything to Terabytes
    if [ "$group_used_unit" = "k" ]; then
        group_used_value=$(echo "scale=40; $group_used_value / 1024" | bc)
        group_used_value=$(echo "scale=40; $group_used_value / 1024" | bc)
        group_used_value=$(echo "scale=40; $group_used_value / 1024" | bc)
    fi

    if [ "$group_quota_unit" = "k" ]; then
        group_quota_value=$(echo "scale=40; $group_quota_value / 1024" | bc)
        group_quota_value=$(echo "scale=40; $group_quota_value / 1024" | bc)
        group_quota_value=$(echo "scale=40; $group_quota_value / 1024" | bc)
    fi

    if [ "$user_used_unit" = "k" ]; then
        user_used_value=$(echo "scale=40; $user_used_value / 1024" | bc)
        user_used_value=$(echo "scale=40; $user_used_value / 1024" | bc)
        user_used_value=$(echo "scale=40; $user_used_value / 1024" | bc)
    fi

    if [ "$group_used_unit" = "M" ]; then
        group_used_value=$(echo "scale=20; $group_used_value / 1024" | bc)
        group_used_value=$(echo "scale=20; $group_used_value / 1024" | bc)
    fi

    if [ "$group_quota_unit" = "M" ]; then
        group_quota_value=$(echo "scale=20; $group_quota_value / 1024" | bc)
        group_quota_value=$(echo "scale=20; $group_quota_value / 1024" | bc)
    fi

    if [ "$user_used_unit" = "M" ]; then
        user_used_value=$(echo "scale=20; $user_used_value / 1024" | bc)
        user_used_value=$(echo "scale=20; $user_used_value / 1024" | bc)
    fi

    if [ "$group_used_unit" = "G" ]; then
        group_used_value=$(echo "scale=10; $group_used_value / 1024" | bc)
    fi

    if [ "$group_quota_unit" = "G" ]; then
        group_quota_value=$(echo "scale=10; $group_quota_value / 1024" | bc)
    fi

    if [ "$user_used_unit" = "G" ]; then
        user_used_value=$(echo "scale=10; $user_used_value / 1024" | bc)
    fi

    # Calculate percentages
    local orange_group_percentage=$(awk "BEGIN {printf \"%.2f\", $group_used_value / $group_quota_value * 100}")
    local orange_user_percentage=$(awk "BEGIN {printf \"%.2f\", $user_used_value / $group_quota_value * 100}")

    # Return the percentage values
    if [ "$orange_group_percentage" = "0.00" ]; then
        echo "\nTotal Used Percentage of Group: <0.01%"
    else
        echo "\nTotal Used Percentage of Group: $orange_group_percentage%"
    fi

    # Make Orange Group Percent Bar
    local orange_group_bar=$(make_percent_bar "$orange_group_percentage" "#FA4616")
    echo "\n$orange_group_bar"

    if [ "$orange_user_percentage" = "0.00" ]; then
        echo "Personal Use Percentage of Group: <0.01%"
    else
        echo "Personal Use Percentage of Group: $orange_user_percentage%"
    fi

    # Make Blue User Percent Bar
    local orange_user_bar=$(make_percent_bar "$orange_user_percentage" "#FA4616")
    echo "\n$orange_user_bar"

    # Check if Orange Storage is Critical
    if (( $(awk -v p="$orange_group_percentage" 'BEGIN { if (p >= 90.00) print 1; else print 0; }') )); then
      echo "Status: $red_x_html"
      echo "Note: Orange Storage Critical. Please clear up your orange directory."
    else
      echo "Status: $green_checkmark_html"
      echo "Note: Orange Storage Under 90%"
    fi
}

getUserEmail() {
    username=$(whoami)
    getEntries=$(getentng -u $username)
    getEntriesOutput=$(echo -e "$getEntries")
    email=$(python /apps/email_storage_alert/bin/extract_email.py "$getEntriesOutput")
    echo "$email"
}

# Storage Quotas #

# Home Quota
home_message=$(bold_underline "Home Quota")
home=$(echo "$(home_quota 2>/dev/null)" | sed '$d')
if [ -z "$home" ]; then
    home="No Home Storage Available"
else
    home_per=$(echo "$(calculate_home_percentage)")
    home_percentage=$(echo "$home_per" | grep -oP 'Percentage Used: \K[0-9.]+')
    if (( $(awk -v p="$home_percentage" 'BEGIN { if (p >= 90.00) print 1; else print 0; }') )); then
        homeStorageCritical=true
    else
        homeStorageCritical=false
    fi
fi

# Blue Quota
blue_message=$(bold_underline "Blue Quota")
blue=$(echo "$(blue_quota 2>/dev/null)" | sed '$d')
if [ -z "$blue" ]; then
    blue="No Blue Storage Available"
else
    blue_per=$(echo "$(calculate_blue_percentage)")
    blue_group_percentage=$(echo "$blue_per" | grep -oP 'Total Used Percentage of Group: \K[0-9.]+')
    blue_user_percentage=$(echo "$blue_per" | grep -oP 'Personal Use Percentage of Group: \K[0-9.]+')
    if (( $(awk -v g="$blue_group_percentage" -v u="$blue_user_percentage" 'BEGIN { if (g >= 90.00 || u >= 90.00) print 1; else print 0; }') )); then
        blueStorageCritical=true
    else
        blueStorageCritical=false
    fi
fi

# Orange Quota
orange_message=$(bold_underline "Orange Quota")
orange=$(echo "$(orange_quota 2>/dev/null)" | sed '$d')
if [ -z "$orange" ]; then
    orange="\nNo Orange Storage Available"
else
    orange_per=$(echo "$(calculate_orange_percentage)")
    orange_group_percentage=$(echo "$orange_per" | grep -oP 'Total Used Percentage of Group: \K[0-9.]+')
    orange_user_percentage=$(echo "$orange_per" | grep -oP 'Personal Use Percentage of Group: \K[0-9.]+')
    if (( $(awk -v g="$orange_group_percentage" -v u="$orange_user_percentage" 'BEGIN { if (g >= 90.00 || u >= 90.00) print 1; else print 0; }') )); then
        orangeStorageCritical=true
    else
        orangeStorageCritical=false
    fi
fi

# Total Storage with Messages
total_storage="$home_message\n$home\n$home_per\n\n$blue_message\n$blue\n$blue_per\n\n$orange_message$orange\n$orange_per"

# Email details
sender="support"
recipient=$(echo "$(getUserEmail)")
if [ "$send_flag" = true ] && [ "$homeStorageCritical" = false ] && [ "$blueStorageCritical" = false ] && [ "$orangeStorageCritical" = false ]; then
    subject="HiPerGator Storage at Noncritical Levels"
else
    subject="HiPerGator Storage at Critical Levels"
fi
body=$(printf "<pre>%s</pre>" "$total_storage")

# Send the email if any storage levels critical
if [ "$homeStorageCritical" = true ] || [ "$blueStorageCritical" = true ] || [ "$orangeStorageCritical" = true ] || [ "$send_flag" = true ]; then
    echo -e "Subject: $subject\nFrom: $sender\nTo: $recipient\nContent-Type: text/html\n$body" | sendmail -t
fi

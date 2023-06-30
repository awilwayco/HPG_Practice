#!/bin/bash

# Declare global variables for percentages
blue_group_percentage=""
blue_user_percentage=""

calculate_blue_percentage() {
    # Run the blue_quota command and capture the output
    quota_output=$(blue_quota)

    # Extract group used and quota values
    group_used=$(echo "$quota_output" | awk 'NR==3{print $2}')
    group_quota=$(echo "$quota_output" | awk 'NR==3{print $3}')
    user_used=$(echo "$quota_output" | awk 'NR==6{print $2}')

    # Extract the numerical part of the variables
    group_used_value="${group_used%[A-Z]*}"
    group_quota_value="${group_quota%[A-Z]*}"
    user_used_value="${user_used%[A-Z]*}"

    # Determine the unit (T or G) for each variable
    group_used_unit="${group_used: -1}"
    group_quota_unit="${group_quota: -1}"
    user_used_unit="${user_used: -1}"

    # Convert everything to Gigabytes
    if [ "$group_used_unit" = "T" ]; then
        group_used_value=$(( group_used_value * 1024 ))
    fi

    if [ "$group_quota_unit" = "T" ]; then
        group_quota_value=$(( group_quota_value * 1024 ))
    fi

    if [ "$user_used_unit" = "T" ]; then
        user_used_value=$(( user_used_value * 1024 ))
    fi

    # Calculate percentages
    blue_group_percentage=$(awk "BEGIN {printf \"%.2f\", $group_used_value / $group_quota_value * 100}")
    blue_user_percentage=$(awk "BEGIN {printf \"%.2f\", $user_used_value / $group_quota_value * 100}")
}

calculate_blue_percentage

echo "Total Used Percentage of Group: $blue_group_percentage%"
echo "Personal Use Percentage of Group: $blue_user_percentage%"

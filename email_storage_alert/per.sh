#!/bin/bash

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
        group_used_value=$(( group_used_value / 1024 ))
    fi

    if [ "$group_quota_unit" = "G" ]; then
        group_quota_value=$(( group_quota_value / 1024 ))
    fi

    if [ "$user_used_unit" = "G" ]; then
        user_used_value=$(( user_used_value / 1024 ))
    fi

    # Calculate percentages
    local blue_group_percentage=$(awk "BEGIN {printf \"%.2f\", $group_used_value / $group_quota_value * 100}")
    local blue_user_percentage=$(awk "BEGIN {printf \"%.2f\", $user_used_value / $group_quota_value * 100}")

    if [ "$blue_group_percentage" = "0.00" ]; then
        echo "Total Used Percentage of Group: <0.01%"
    else
        echo "Total Used Percentage of Group: $blue_group_percentage%"
    fi

    if [ "$blue_user_percentage" = "0.00" ]; then
        echo "Personal Use Percentage of Group: <0.01%"
    else
        echo "Personal Use Percentage of Group: $blue_user_percentage%"
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
        group_used_value=$(( group_used_value / 1024 ))
    fi

    if [ "$group_quota_unit" = "G" ]; then
        group_quota_value=$(( group_quota_value / 1024 ))
    fi

    if [ "$user_used_unit" = "G" ]; then
        user_used_value=$(( user_used_value / 1024 ))
    fi

    # Calculate percentages
    local orange_group_percentage=$(awk "BEGIN {printf \"%.2f\", $group_used_value / $group_quota_value * 100}")
    local orange_user_percentage=$(awk "BEGIN {printf \"%.2f\", $user_used_value / $group_quota_value * 100}")
    
    if [ "$orange_group_percentage" = "0.00" ]; then
        echo "Total Used Percentage of Group: <0.01%"
    else
        echo "Total Used Percentage of Group: $orange_group_percentage%"
    fi

    if [ "$orange_user_percentage" = "0.00" ]; then
        echo "Personal Use Percentage of Group: <0.01%"
    else
        echo "Personal Use Percentage of Group: $orange_user_percentage%"
    fi

}

calculate_blue_percentage

#!/bin/bash

# Function to format text as bold
bold() {
  echo "<b>$1</b>"
}

# Store the bold message in a variable
bold_message=$(bold "This is a bold message")

# Email details
sender="awilwayco@ufl.edu"
recipient="awilwayco@ufl.edu"
subject="Bold Message"
body="<html><body><p>$bold_message</p></body></html>"

# Send the email
echo -e "Subject: $subject\nFrom: $sender\nTo: $recipient\nContent-Type: text/html\n\n$body" | sendmail -t

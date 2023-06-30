#!/bin/bash

# Function to format text as underlined
underline() {
  echo "<u>$1</u>"
}

# Store the underlined message in a variable
underlined_message=$(underline "This is an underlined message")

# Email details
sender="awilwayco@ufl.edu"
recipient="awilwayco@ufl.edu"
subject="Underlined Message"
body="<html><body><p>$underlined_message</p></body></html>"

# Send the email
echo -e "Subject: $subject\nFrom: $sender\nTo: $recipient\nContent-Type: text/html\n\n$body" | sendmail -t


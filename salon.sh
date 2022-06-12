#!/bin/bash
PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"


CREATE_APPOINTMENT()
{
  SERVICE_ID=$1
  CUSTOMER_ID=$2
  SERVICE_NAME=$3
  CUSTOMER_NAME=$4
  # Get appointment time
  echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
  read SERVICE_TIME
  if [[ -z $SERVICE_TIME ]]
    then
    echo -e 'Time entered blank please try again.\n'
    CREATE_APPOINTMENT $SERVICE_ID $CUSTOMER_ID
  else
    # Create appointment
    CREATE_APPOINTMENT_RESULT=$($PSQL "INSERT INTO APPOINTMENTS(CUSTOMER_ID,SERVICE_ID,TIME) VALUES ($CUSTOMER_ID,$SERVICE_ID,'$SERVICE_TIME')")
    if [[ -z $CREATE_APPOINTMENT_RESULT ]]
      then
        SERVICE_LIST "Error creating appointment. Please try again."
    else
      echo -e "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
    fi 
  fi
}

SERVICE_APPOINTMENT()
{
  SERVICE_ID=$1
  SERVICE_NAME=$($PSQL "SELECT NAME FROM SERVICES WHERE SERVICE_ID=$SERVICE_ID")
  # Get customer phone
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE
  CUSTOMER_ID=$($PSQL "SELECT CUSTOMER_ID FROM CUSTOMERS WHERE PHONE='$CUSTOMER_PHONE'")
  if [[ -z $CUSTOMER_ID ]]
    then
    # Create new customer
    echo -e "\nI don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME
    if [[ -z $CUSTOMER_NAME || -z $CUSTOMER_PHONE ]]
      then
        echo -e "Some of the details entered were missing please try again."
        SERVICE_APPOINTMENT $SERVICE_ID
      else 
        # Create customer in db
        CREATE_CUSTOMER_RESULT=$($PSQL "INSERT INTO CUSTOMERS (NAME,PHONE) VALUES ('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
        if [[ -z $CREATE_CUSTOMER_RESULT ]]
          # If unsuccessful
          then
            SERVICE_LIST "Something went wrong please try again"
        else 
          # Get customer id
          CUSTOMER_ID=$($PSQL "SELECT CUSTOMER_ID FROM CUSTOMERS WHERE PHONE='$CUSTOMER_PHONE'")
          # Create appointment
          CREATE_APPOINTMENT $SERVICE_ID $CUSTOMER_ID $SERVICE_NAME $CUSTOMER_NAME
        fi
    fi
  else
    # Get customer name
    CUSTOMER_NAME=$($PSQL "SELECT NAME FROM CUSTOMERS WHERE CUSTOMER_ID=$CUSTOMER_ID")
    # Create appointment
    CREATE_APPOINTMENT $SERVICE_ID $CUSTOMER_ID $SERVICE_NAME $CUSTOMER_NAME
  fi
}

SERVICE_LIST()
{
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi
  # Display numbered list of services
  SERVICES=$($PSQL "SELECT * FROM SERVICES")
  echo "$SERVICES" | while read SERVICE_ID BAR NAME
  do
    echo -e "$SERVICE_ID) $NAME"
  done
  read SERVICE_ID_SELECTED
  if [[ -z $SERVICE_ID_SELECTED ]]
    then
      # Display the menu again
      SERVICE_LIST
  else 
  # Get the service
  SERVICE=$($PSQL "SELECT * FROM SERVICES WHERE SERVICE_ID=$SERVICE_ID_SELECTED")
    # If service does not exist
    if [[ -z $SERVICE ]]
      then
        # Display the menu again
        SERVICE_LIST "I could not find that service. What would you like today?"
    else 
      # Create the appointment
      SERVICE_APPOINTMENT $SERVICE_ID_SELECTED
    fi
  fi
}

echo -e "\n~~~~~ MY SALON ~~~~~\n\n\nWelcome to My Salon, how can I help you?\n"
SERVICE_LIST
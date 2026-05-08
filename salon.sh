#! /bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

if [[ $1 == reset ]]; then
  _=$($PSQL "TRUNCATE TABLE appointments, customers, services")
  _=$($PSQL "ALTER SEQUENCE services_service_id_seq RESTART WITH 1")
  _=$($PSQL "INSERT INTO services(name) VALUES('buzz'), ('amputation'), ('Expo Claw™ application')")
else
  echo -e "\n~~~~~ MY SALON ~~~~~\n"

  MAIN_MENU() {
    if [[ $1 ]]; then
      echo -e "\n$1"
    else
      echo -e "Welcome to My Salon, how can I help you?\n"
    fi

    SERVICES=$($PSQL "SELECT name FROM services")
    mapfile -t SERVICES <<< "$SERVICES"
    SERVICE_COUNT=${#SERVICES[@]}
    for INDEX in "${!SERVICES[@]}"; do
      SERVICE=$(sed "s/ |/\"/" <<< "${SERVICES[$INDEX]}")
      echo "$((($INDEX + 1))))$SERVICE"
    done
    
    read SERVICE_ID_SELECTED
    ((--SERVICE_ID_SELECTED))

    if [[ "$SERVICE_ID_SELECTED" =~ ^[0-9]+$ && $SERVICE_ID_SELECTED -ge 0 && $SERVICE_ID_SELECTED -lt $SERVICE_COUNT ]]; then
      echo -e "\nWhat's your phone number?"
      read CUSTOMER_PHONE

      CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")

      if [[ -z $CUSTOMER_NAME ]]
      then
        echo -e "\nI don't have a record for that phone number, what's your name?"
        read CUSTOMER_NAME

        INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')") 
      fi

      CUSTOMER_NAME=$(sed 's/ //' <<< $($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'"))
      SERVICE_NAME=$(sed 's/ //' <<< "${SERVICES[$SERVICE_ID_SELECTED]}")

      echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
      read SERVICE_TIME

      CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")

      INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $(((SERVICE_ID_SELECTED + 1))), '$SERVICE_TIME')")
      
      echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
    else
      MAIN_MENU "I could not find that service. What would you like today?"
    fi
  }

  MAIN_MENU
fi
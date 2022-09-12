#!/bin/bash

function execute_queries( ) {

  echo ""
  echo "EXECUTING QUERY ZAPS FOR FUNDING APP: $app_id -> "
  echo ""

  echo "ApplicationId: $app_id"
  echo "40% payment amount: $amount"
  echo "Case id: $case_id"
  echo "Form id: $form_id"
  echo ""
 
#  NOTE: The database name stated after the conduit cmd should be modified to the appropriate DB name. 
# (i.e. cf conduit [DB-NAME] --local-port 7081 -- psql -t -c "QUERY"")

# UPDATE FUNDING APP
  update_result=`cf conduit funding-frontend-research --local-port 7081 -- psql -t -c "UPDATE funding_applications SET status = 3 WHERE id = '$app_id'"`&&
  update_result=`echo $payment_request_id | sed 's/ *$//g' | grep -o '^\S*'`
  if [[ $update_result == *"Exit"* ]]; then
    echo "Error updating status of funding application $app_id"
    exit 1
  else
    echo "Successfully updated status of funding application $app_id"
    echo ""
  fi

# CREATE NEW PAYMENT REQUEST
  payment_request_id=`cf conduit funding-frontend-research --local-port 7081 -- psql -t -c "INSERT INTO payment_requests (amount_requested, created_at, updated_at, submitted_on) VALUES( $amount, NOW(), NOW(), '0001-01-01 00:00:00.000000') RETURNING id"`&&
  payment_request_id=`echo $payment_request_id | sed 's/ *$//g' | grep -o '^\S*'`
  if [[ $payment_request_id == *"Exit"* ]]; then
    echo "Error creating payment_request for funding application $app_id"
    exit 1
  else
    echo "Successfully created payment_request with id: $payment_request_id"
    echo ""
  fi

# CREATE JOIN ROW IN FUNDING APPLICATIONS PAYMENT REQUESTS
  funding_app_pay_request_id=`cf conduit funding-frontend-research --local-port 7081 -- psql -t -c "INSERT INTO funding_applications_pay_reqs (funding_application_id, payment_request_id, created_at, updated_at) VALUES( '$app_id', '$payment_request_id', NOW(), NOW()) RETURNING id"`&&
  funding_app_pay_request_id=`echo $funding_app_pay_request_id | sed 's/ *$//g' | grep -o '^\S*'`
  if [[ $funding_app_pay_request_id == *"Exit"* ]]; then
    echo "Error creating funding_applications_pay_reqs join row for funding application $app_id"
    exit 1
  else
    echo "Successfully created funding_applications_pay_reqs row with id: $funding_app_pay_request_id"
    echo ""
  fi

# CREATE A NEW COMPLETED ARREARS JOURNEY TRACKER WITH OUR PAYMENT REQUEST
  completed_arrears_journey_id=`cf conduit funding-frontend-research --local-port 7081 -- psql -t -c "INSERT INTO completed_arrears_journeys (funding_application_id, payment_request_id, salesforce_form_id, submitted_on, created_at, updated_at) VALUES( '$app_id', '$payment_request_id', '$form_id', '0001-01-01 00:00:00.000000', NOW(), NOW()) RETURNING id"`&&
  completed_arrears_journey_id=`echo $completed_arrears_journey_id | sed 's/ *$//g' | grep -o '^\S*'`
   if [[ $completed_arrears_journey_id == *"Exit"* ]]; then
    echo "Error creating completed_arrears_journeys join row for funding application $app_id"
    exit 1
  else
    echo "Successfully created completed_arrears_journeys row with id: $completed_arrears_journey_id"
    echo ""
  fi

  echo "COMPLETED ZAP FOR APP WITH ID: $app_id"
  echo ""
  echo "|-------------------------------------------------------|"
}

echo "This script will run zaps against a Postgres instance deployed on GovPaas, using the `Conduit` Cloud Foundry plugin provided by gov-alpha. The script executes queries to add a 40% payment request to an applications, simulating a completed M1 40% Journey. \n\n"

read -p 'Username: ' uservar
read -sp 'Password: ' passvar

# The -s flag should be modified to point at the correct environnement in which the target DB is situated
eval cf login -a https://api.london.cloud.service.gov.uk -u ${uservar} -p ${passvar}  -o national-lottery-heritage-fund -s sandbox

while IFS="," read -r amount app_id case_id form_id
do
  amount=$amount
  app_id=$app_id
  case_id=$case_id
  form_id=$form_id
 
  execute_queries
done < <(tail -n +2 zap_csv_test.csv)

echo ""
echo " *** All zaps run and complete *** "

exit 0
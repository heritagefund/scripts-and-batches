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

# UPDATE FUNDING APP
  query_result=`cf conduit funding-frontend-research --local-port 7081 -- psql -t -c "UPDATE funding_applications SET status = 3 WHERE id = '$app_id'"`
  echo "Successfully updated funding application $app_id status to 3"
  echo ""

# CREATE NEW PAYMENT REQUEST
  payment_request_id=`cf conduit funding-frontend-research --local-port 7081 -- psql -t -c "INSERT INTO payment_requests (amount_requested, created_at, updated_at, submitted_on) VALUES( $amount, NOW(), NOW(), '0001-01-01 00:00:00.000000') RETURNING id"`
  # TRIM SPACES AND INSERT 0 1
  payment_request_id=`echo $payment_request_id | sed 's/ *$//g' | grep -o '^\S*'`
  echo "Successfully created payment request with id: $payment_request_id"
  echo ""

# CREATE JOIN ROW IN FUNDING APPLICATIONS PAYMENT REQUESTS
  funding_app_pay_request_id=`cf conduit funding-frontend-research --local-port 7081 -- psql -t -c "INSERT INTO funding_applications_pay_reqs (funding_application_id, payment_request_id, created_at, updated_at) VALUES( '$app_id', '$payment_request_id', NOW(), NOW()) RETURNING id"`
  # TRIM SPACES AND INSERT 0 1
  funding_app_pay_request_id=`echo $funding_app_pay_request_id | sed 's/ *$//g' | grep -o '^\S*'`
  echo "Successfully created funding_applications_pay_reqs row with id: $funding_app_pay_request_id"
  echo ""

# CREATE A NEW COMPLETED ARREARS JOURNEY TRACKER WITH OUR PAYMENT REQUEST
  completed_arrears_journey_id=`cf conduit funding-frontend-research --local-port 7081 -- psql -t -c "INSERT INTO completed_arrears_journeys (funding_application_id, payment_request_id, salesforce_form_id, submitted_on, created_at, updated_at) VALUES( '$app_id', '$payment_request_id', '$form_id', '0001-01-01 00:00:00.000000', NOW(), NOW()) RETURNING id"`
  # TRIM SPACES AND INSERT 0 1
  completed_arrears_journey_id=`echo $completed_arrears_journey_id | sed 's/ *$//g' | grep -o '^\S*'`
  echo "Successfully created completed_arrears_journeys row with id: $completed_arrears_journey_id"
  echo ""

  echo "COMPLETED ZAP FOR APP WITH ID: $app_id"
  echo ""
  echo "--------------------"
}

echo "This script is designed to to run zaps against Postgres in GovPaas to update 40% applications \n\n"

read -p 'Username: ' uservar
read -sp 'Password: ' passvar

eval cf login -a https://api.london.cloud.service.gov.uk -u ${uservar} -p ${passvar}  -o national-lottery-heritage-fund -s sandbox

while IFS="," read -r amount app_id case_id form_id
do
  
  amount=$amount
  app_id=$app_id
  case_id=$case_id
  form_id=$form_id
 
  execute_queries

done < <(tail -n +2 zap_csv_test.csv)


exit 0
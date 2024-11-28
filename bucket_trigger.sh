#!/bin/bash
set -euo pipefail

<< comment

	Author:Arijit Das
	Version:1.0
	
	Description: This script sends an email notification to the intended party when a new object is uploaded in the GCS.
 		     main.py is created for the 2 cloud functions
 		     requirements.txt contains the needed dependencies that need to be installed  

	Pre-requisites:
  		1) A pre-configured gcp acoount with an active project
		2) A virtual machine running ubuntu in the project
		3) A service account with the Role Admim and Project IAM Admin IAM Roles and a public/private key stored in the system
	 	3) gcloud cli,python,pip  pre-installed in the system
 		4) A SendGrid account with a valid api key
		5) The bucket,IAM role,pubsub topics and cloud functions of the same name should not exist
		6) The file should be executable
comment
   # Important Variables
     project_name="enter the project name"
     service_account="enter the name of the service account"
     region="enter the region"
     project_number=$(gcloud projects describe "$project_name" --format="value(projectNumber)")
     API_KEY="enter the api key(best to use env variables)"
     bucket_name="enter the desired bucket name(must be globally unique)"
     vm="enter the name of the vm being usd to run the script"
     topic_name="enter th desired topic name"
     custom_role="enter the desired name of the IAM custom role"
     key_location="enter tha location where the key is stored in system"

    # Installing the needed python dependencies and creating a vitual enviroment
     python3 -m venv myenv
     source myenv/bin/activate
     pip install --upgrade pip
     pip install -r requirements.txt

     if [ $? -ne 0 ]; then
      echo " failed to install required python dependencies"
      exit 1
     else
      echo " successfully installed the python dependencies"
     fi

      # Set the service account as primary service account of the project 
        gcloud config set account "$service_account"

	if [ $? -ne 0 ]; then
          echo "Error while setting the account. Exiting..."
          exit 1
        else
          echo "Service account set successfully: $service_account"
        fi

       # activating the service account
       gcloud auth activate-service-account --key-file="${key_location}"

       if [ $? -ne 0 ]; then
          echo "Error while activating the account. Exiting..."
          exit 1
        else
          echo "Service account activated successfully: $service_account"
        fi


       # creating the custom IAM roles
 	gcloud iam roles create $custom_role \
 	--project=$project_name \
 	--title="Custom role for needed services" \
 	--permissions="storage.objects.get,storage.objects.create,storage.objects.list,storage.buckets.create,storage.buckets.get,pubsub.topics.create,pubsub.topics.publish,pubsub.subscriptions.create,pubsub.topics.get,cloudfunctions.functions.create,cloudfunctions.functions.invoke,cloudfunctions.functions.get,cloudfunctions.functions.generateUploadUrl,cloudfunctions.functions.call,cloudfunctions.functions.update,cloudfunctions.functions.list,cloudfunctions.operations.get,cloudbuild.builds.create,cloudbuild.builds.list,cloudbuild.builds.get,run.services.create,run.services.update,run.services.get,run.services.delete,serviceusage.services.enable,iam.serviceAccounts.actAs,artifactregistry.repositories.downloadArtifacts"
        
 	if [ $? -ne 0 ]; then
          echo " failed to create the custom IAM Role"
          exit 1
         else
          echo " successfully created the custom IAM Role"
         fi
 
      # adding the custom role to the service account
        gcloud projects add-iam-policy-binding ${project_name} \
        --member="serviceAccount:${service_account}" \
        --role="projects/${project_name}/roles/${custom_role}"
 
        if [ $? -ne 0 ]; then
         echo " failed to add custom role to the service account"
         exit 1
        else
         echo "custom role added to the service account"
        fi
 
      # creating a cloud storage bucket
        gcloud storage buckets create gs://$bucket_name \
        --location=$region 
 
        if [ $? -ne 0 ]; then
         echo " failed to create the storage bucket"
         exit 1
        else
         echo "storage bucket created successfully"
        fi

      # providing the pubsub publisher role to the bucket's service account
        gcloud projects add-iam-policy-binding $project_name \
        --member="serviceAccount:service-${project_number}@gs-project-accounts.iam.gserviceaccount.com" \
        --role="roles/pubsub.publisher"

	
     # creating the eventarc agent and giving it the needed IAM role
        gcloud services enable eventarc.googleapis.com 
 	eventarc_agent="service-${project_number}@gcp-sa-eventarc.iam.gserviceaccount.com"

	gcloud projects add-iam-policy-binding $project_name \
        --member="serviceAccount:${eventarc_agent}" \
        --role="roles/eventarc.serviceAgent"

	if [ $? -ne 0 ]; then
         echo " failed to add custom role to the service account"
         exit 1
        else
         echo "custom role added to the service account"
        fi

     # creating a pub/sub topic
        gcloud pubsub topics create $topic_name

	if [ $? -ne 0 ]; then
         echo " failed to create the pubsub topic"
         exit 1
        else
         echo "successfully created the pubsub topic"
        fi
 
     # enabling the needed api's
        gcloud services enable cloudbuild.googleapis.com
        gcloud services enable run.googleapis.com

     # creating a cloud function that listens for gcs updates
        gcloud functions deploy gcs-to-pubsub \
        --runtime=python312 \
        --trigger-resource=$bucket_name \
        --trigger-event=google.storage.object.finalize \
        --entry-point=gcs_trigger \
        --source=. \
        --timeout=300s \
        --set-env-vars PROJECT_ID=$project_name,TOPIC_ID=$topic_name,SENDGRID_API_KEY=$API_KEY


      if [ $? -ne 0 ]; then
        echo " failed to create the cloud function"
        exit 1
      else
        echo "cloud fucntion created successfully"
      fi

     # creating a second cloud function that is subscribed to the topic and sends emails
       gcloud functions deploy pubsub-to-email \
       --runtime=python312 \
       --trigger-topic=$topic_name \
       --entry-point=send_email \
       --source=. \
       --timeout=300s \
       --set-env-vars PROJECT_ID=$project_name,TOPIC_ID=$topic_name,SENDGRID_API_KEY=$API_KEY

       if [ $? -ne 0 ]; then
        echo " failed to create the cloud function"
        exit 1
       else
        echo "cloud fucntion created successfully"
       fi

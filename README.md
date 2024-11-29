

  <h1>GCS Event Notification Script</h1>
  
## 💻 Overview

This Bash script automates the setup of a GCP project to send email notifications when a new object is uploaded to a Google Cloud Storage (GCS) bucket. It creates the required resources, including IAM roles, Pub/Sub topics, and Cloud Functions, and integrates SendGrid for email notifications.

## 📕Features

   - Automates GCP resource creation and configuration.
   - Uses SendGrid for email notifications.
   - Implements two Cloud Functions:
      -  **GCS-to-Pub/Sub**: Monitors the GCS bucket for new objects and publishes messages to a Pub/Sub topic.
       - **Pub/Sub-to-Email**: Subscribes to the topic and sends email notifications.
   - Handles errors gracefully and includes validation steps.

## ✅ Prerequisites

Before running the script, ensure the following:

  - **`GCP Project`**: An active GCP project. 
  - **`Ubuntu VM`**: A virtual machine running Ubuntu. 
  - **`Service Account`**: A service account with the following roles:
     - Project IAM Admin( to create custom roles) 
    
  - **`GCP CLI Tools`**: - `gcloud`  `Python` and `pip` 
  - **`SendGrid Account`**: A valid **SendGrid** API key.
  - **`System Requirements`**: - The script must have execution permissions.
  - The bucket, IAM role, Pub/Sub topic, and Cloud Functions with the same name should **not** pre-exist.

## 🛠️  Setting up the Project  
## 1. Clone or Copy the Script 

	git clone https://github.com/Arijit9721/Google-Storage-Trigger-with-Bash.git

Save the script file and make it executable:

    chmod +x script_name.sh

## 2. Update Variables

Replace placeholder values with actual project details in the script:
- **`project_name`**: Your GCP project name.  
- **`service_account`**: Service account email.  
- **`region`**: GCP region for the resources.  
- **`API_KEY`**: SendGrid API key (recommended: use environment variables).  
- **`bucket_name`**: Unique name for the GCS bucket.  
- **`vm`**: Name of the VM running the script.  
- **`topic_name`**: Name for the Pub/Sub topic.  
- **`custom_role`**: Name for the custom IAM role.  
- **`key_location`**: Path to the service account key file.  

 
## ✏️ Script Workflow

   - **Python Setup:**
     - Creates a virtual environment.
     - Installs required Python dependencies from `requirements.txt`.

- **Service Account Configuration:**
  - Sets and activates the provided service account.

- **Custom IAM Role Creation:**
  - Grants permissions required for bucket and Cloud Function operations.

- **Resource Creation:**
  - Creates a GCS bucket.
  - Creates a Pub/Sub topic.
  - Deploys Cloud Functions.

- **API Enablement:**
  - Enables necessary APIs (e.g., Cloud Functions, Eventarc).

- **Cloud Functions Deployment:**
  - **`gcs-to-pubsub`**: Publishes messages to a topic when new objects are uploaded.
  - **`pubsub-to-email`**: Sends email notifications using the SendGrid API.


## 🎯Usage

Run the script:

	 ./script_name.sh

Monitor the output for error messages or success confirmations. Upon completion:

	The GCS bucket will publish events to the Pub/Sub topic.
	The Pub/Sub topic will trigger an email notification via SendGrid.

## 🔧 Error Handling 

The script exits on errors with appropriate messages. Check the logs for any issues with:

 -   Dependency installation.
 -  IAM role creation or binding.
 - Cloud Function deployment.
    

## 📅 Notes 

  ✅ Ensure all prerequisites are fulfilled before running the script.
   
  🔒 Store sensitive information (e.g., API keys) securely using environment variables.
  
  🛠 The script is designed for Ubuntu environments with GCP tools pre-installed. Adjustments may be needed for other setups.


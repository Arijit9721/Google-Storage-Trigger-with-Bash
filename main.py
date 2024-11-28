from google.cloud import pubsub_v1
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail
import json
import os
import requests
import base64

# Initialize Pub/Sub Publisher
publisher = pubsub_v1.PublisherClient()
project = os.getenv("PROJECT_ID")
topic = os.getenv("TOPIC_ID")
topic_path = publisher.topic_path(project, topic)

# SendGrid API Key
api_key = os.getenv("SENDGRID_API_KEY")
if api_key is None:
    raise ValueError("SENDGRID_API_KEY is not set.")

# GCS Trigger Function
def gcs_trigger(event, context):
    file_name = event.get('name')
    bucket_name = event.get('bucket')

    # Validate event data
    if not file_name or not bucket_name:
        print("Missing file name or bucket name in the event data.")
        return

    # Create a JSON message
    message = {
        "file_name": file_name,
        "bucket_name": bucket_name
    }
    message_json = json.dumps(message).encode("utf-8")

    # Publish to Pub/Sub
    try:
        future = publisher.publish(topic_path, message_json)
        print(f"Message published: {future.result()}")
    except Exception as e:
        print(f"Error publishing message to Pub/Sub: {e}")


# Send Email Function
def send_email(data, context):
    try:
        # Decode Pub/Sub message 
        pubsub_message = base64.b64decode(data["data"]).decode("utf-8")
        if not pubsub_message:
            print("Empty or missing data in the Pub/Sub message.")
            return

        message_data = json.loads(pubsub_message)

        file_name = message_data.get('file')
        bucket_name = message_data.get('bucket')

        if not file_name or not bucket_name:
            print("Missing file_name or bucket_name in Pub/Sub message.")
            return

        # Email details
        from_email = 'sender@gmail.com'
        to_email = 'receiver@gmail.com'
        subject = 'GCS Object Creation Notification'
        content = f"An object was created in your bucket. Here are the details:\n\nFile: {file_name}\nBucket: {bucket_name}"

        # Create and send the email
        message = Mail(
            from_email=from_email,
            to_emails=to_email,
            subject=subject,
            plain_text_content=content
        )
        sg = SendGridAPIClient(api_key)
        response = sg.send(message)
        print(f"Email sent successfully! Status: {response.status_code}")
    except json.JSONDecodeError as e:
        print(f"Error decoding JSON from Pub/Sub message: {e}")
    except requests.exceptions.Timeout as e:
        print(f"Timeout error: {e}")
    except Exception as e:
        print(f"Error sending email: {e}")


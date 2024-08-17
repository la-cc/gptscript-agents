#!/bin/sh

# Function to zip and encrypt a file
encrypt_file() {
    local file_to_encrypt="$1"
    local encryption_key="$2"
    # Zip and encrypt the file
    7z a -tzip -p"$encryption_key" -mem=AES256 "${file_to_encrypt}.zip" "$file_to_encrypt"
    if [ $? -eq 0 ]; then
        echo "Zip and encryption successful: ${file_to_encrypt}.zip"
        # Optionally, remove the original file to save space
        rm "$file_to_encrypt"
    else
        echo "Error during zip and encryption of: ${file_to_encrypt}"
    fi
}

# Function to set the AWS configuration
init_aws_config() {
    # Set the AWS credentials
    aws configure set aws_access_key_id "$AWS_S3_ACCESS_KEY_ID"
    aws configure set aws_secret_access_key "$AWS_S3_SECRET_ACCESS_KEY"
}

# Function to create a dump of each database
backup_databases() {
    OLD_IFS="$IFS"
    IFS=','
    for db_name in $DATABASE_NAMES; do
        echo "Creating dump for: $db_name"
        # Define the filename for the dump
        dump_file="${PWD}/${db_name}_$(date +%Y-%m-%d).sqlc"
        # Create the dump
        PGPASSWORD=$DATABASE_PASSWORD pg_dump -h $DATABASE_HOSTNAME -p $DATABASE_PORT -U $DATABASE_USER -F c -b -v -f "$dump_file" $db_name
        if [ $? -eq 0 ]; then
            echo "Backup successful: ${db_name}"
            # Call encrypt_file function to zip and encrypt the dump file
            encrypt_file "$dump_file" "$ENCRYPTION_KEY"
        else
            echo "Error during backup of: ${db_name}"
        fi
    done
    IFS="$OLD_IFS"
}

# New function to upload encrypted files
upload_encrypted_files() {
    for file in *.zip; do
        echo "Uploading: $file"
        aws s3 cp "$file" "s3://${AWS_S3_BUCKET}/$file" --endpoint-url "$AWS_S3_ENDPOINT_URL"
        if [ $? -eq 0 ]; then
            echo "Upload successful: $file"
            # Optionally, remove the local file to save space
            rm "$file"
            # Check if ENABLE_WEBHOOK_ENDPOINT is set to true before calling push_to_webhook_endpoint
            if [ "$ENABLE_WEBHOOK_ENDPOINT" = "true" ]; then
                # Call push_to_webhook_endpoint function to notify the webhook about the upload
                push_to_webhook_endpoint "$file"
            fi
        else
            echo "Error during upload of: $file"
        fi
    done
}

push_to_webhook_endpoint() {
    local uploaded_file="$1"
    echo "Notifying webhook about the upload of: $uploaded_file"
    # use curl to send a POST request to the webhook endpoint
    curl -X POST -H "Content-Type: application/json" \
        -d "{
        \"filename\": \"$uploaded_file\",
        \"status\": \"uploaded\",
        \"summary\": \"Backup file uploaded successfully\",
        \"text\": \"The backup file $uploaded_file has been successfully uploaded.\"
        }" "$WEBHOOK_ENDPOINT"
    if [ $? -eq 0 ]; then
        echo "Webhook notification successful for: $uploaded_file"
    else
        echo "Error during webhook notification for: $uploaded_file"
    fi
}

main() {
    # Set the AWS configuration
    init_aws_config
    # Create a dump of each database
    backup_databases
    # Upload the encrypted files to S3
    upload_encrypted_files

}

main

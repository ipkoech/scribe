require "azure_blob"

class AzureService
  def initialize
    @client = AzureBlob::Client.new(
      account_name: Rails.application.credentials.dig(:azure, :storage_account_name),
      access_key: Rails.application.credentials.dig(:azure, :storage_access_key),
      container: Rails.application.credentials.dig(:azure, :container),
    )
    @container = Rails.application.credentials.dig(:azure, :container)
  end

  def upload(file, user_id, prefix = nil)
    blob_name = generate_blob_name(file.original_filename, user_id, prefix)
    @client.create_block_blob(full_blob_name(blob_name), file.read, content_type: file.content_type)
    generate_url(blob_name)
  end

  # Download the blob
  def download(blob_url)
    blob_name = extract_blob_name(blob_url)
    @client.get_blob(full_blob_name(blob_name))
  end

  # Delete the blob
  def delete(blob_url)
    blob_name = extract_blob_name(blob_url)
    @client.delete_blob(full_blob_name(blob_name))
  end

  # Generate a signed URL
  def generate_signed_url(blob_url, expiry_time = 1.hour.from_now)
    blob_name = extract_blob_name(blob_url)
    @client.signed_uri(full_blob_name(blob_name), permissions: "r", expiry: expiry_time.utc.iso8601).to_s
  end

  private

  # Constructs the full blob name including the container
  def full_blob_name(blob_name)
    "#{@container}/#{blob_name}"
  end

  # Generates the URL for the blob
  def generate_url(blob_name)
    full_name = full_blob_name(blob_name)
    "https://#{Rails.application.credentials.dig(:azure, :storage_account_name)}.blob.core.windows.net/#{full_name}"
  end

  # Generates a blob name using user ID and optional prefix
  def generate_blob_name(filename, user_id, prefix = nil)
    if prefix
      "#{prefix}/#{user_id}/#{filename}"
    else
      "#{user_id}/#{filename}"
    end
  end

  # Extracts the blob name (path after the container) from the URL
  def extract_blob_name(blob_url)
    uri = URI.parse(blob_url)
    # Remove the leading slash and container name
    uri.path.sub(%r{^/[^/]+/}, "")
  end
end

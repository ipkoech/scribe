class MediaController < ApplicationController
  before_action :set_medium, only: %i[show update destroy download serve]
  before_action :authenticate_user!

  # GET /media
  def index
    blob_service = AzureService.new
    content_types = params[:content_type]

    # Retrieve only the media files that belong to the current user
    @media = if content_types.present?
        current_user.media.where(content_type: content_types)
      else
        current_user.media
      end

    media_with_urls = @media.map do |medium|
      signed_url = generate_signed_url_for_medium(medium, blob_service)
      build_media_response(medium, signed_url)
    end

    render json: media_with_urls
  end

  # GET /media/1
  def show
    blob_service = AzureService.new
    signed_url = generate_signed_url_for_medium(@medium, blob_service)

    render json: build_media_response(@medium, signed_url)
  end

  # Download the file
  def download
    blob_service = AzureService.new
    begin
      # Extract the blob name from the Azure URL
      blob_name = extract_blob_name(@medium.azure_url)

      blob_service.download(blob_name)
      render json: { message: "File downloaded successfully" }
    rescue AzureBlob::Http::FileNotFoundError => e
      Rails.logger.error("File not found: #{e.message}")
      render json: { error: "File not found in Azure Blob Storage" }, status: :not_found
    rescue StandardError => e
      Rails.logger.error("Failed to download file: #{e.message}")
      render json: { error: "Failed to download file: #{e.message}" }, status: :internal_server_error
    end
  end

  # POST /media
  def create
    blob_service = AzureService.new
    uploaded_file = params[:file]

    begin
      azure_url = blob_service.upload(uploaded_file, current_user.id)
      encoded_azure_url = azure_url.split("/", -1).tap do |parts|
        parts[-1] = URI.encode_www_form_component(parts[-1]) if parts.size > 1
      end.join("/")
      @media = current_user.media.new(
        title: uploaded_file.original_filename,
        azure_url: encoded_azure_url,
        content_type: uploaded_file.content_type,
        size: uploaded_file.size,
      )

      if @media.save
        render json: @media, status: :created
      else
        render json: @media.errors, status: :unprocessable_entity
      end
    rescue StandardError => e
      render json: { error: "Failed to upload file: #{e.message}" }, status: :internal_server_error
    end
  end

  # PATCH/PUT /media/1
  def update
    if @medium.update(medium_params)
      render json: @medium
    else
      render json: @medium.errors, status: :unprocessable_entity
    end
  end

  # DELETE /media/1
  def destroy
    blob_service = AzureService.new
    begin
      blob_service.delete(extract_blob_name(@medium.azure_url))
      @medium.destroy!
      render json: { message: "Media deleted successfully" }
    rescue StandardError => e
      render json: { error: "Failed to delete media: #{e.message}" }, status: :internal_server_error
    end
  end

  # Serve the media file
  def serve
    blob_service = AzureService.new
    signed_url = generate_signed_url_for_medium(@medium, blob_service)

    render json: {
      media: @medium,
      download_url: signed_url,
    }
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_medium
    @medium = Medium.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def medium_params
    params.require(:medium).permit(:title, :azure_url, :content_type, :size, :user_id, :file)
  end

  # Helper method to generate a signed URL for a medium
  def generate_signed_url_for_medium(medium, blob_service)
    blob_name = extract_blob_name(medium.azure_url)
    blob_service.generate_signed_url(blob_name)
  end

  # Helper method to extract the blob name from the full URL
  def extract_blob_name(blob_url)
    begin
      uri = URI.parse(blob_url)
      # Remove the leading slash and container name
      uri.path.sub(%r{^/+}, "")
    rescue URI::InvalidURIError
      # Handle the case where the URL is invalid, likely due to spaces or special characters
      # Split the URL by the last slash and URL-decode the last part (the blob name)
      container_url, blob_name = blob_url.split("/", -1) # Split by last slash
      URI.decode_www.form_urlencoded_str(blob_name) if blob_name # Decode if blob_name exists
    end
  end

  # Helper method to build the JSON response for a medium
  def build_media_response(medium, signed_url)
    {
      id: medium.id,
      title: medium.title,
      content_type: medium.content_type,
      size: medium.size,
      created_at: medium.created_at,
      updated_at: medium.updated_at,
      azure_url: medium.azure_url,
      access_url: signed_url,
    }
  end
end

require "test_helper"

class DraftVersionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @draft_version = draft_versions(:one)
  end

  test "should get index" do
    get draft_versions_url, as: :json
    assert_response :success
  end

  test "should create draft_version" do
    assert_difference("DraftVersion.count") do
      post draft_versions_url, params: { draft_version: {} }, as: :json
    end

    assert_response :created
  end

  test "should show draft_version" do
    get draft_version_url(@draft_version), as: :json
    assert_response :success
  end

  test "should update draft_version" do
    patch draft_version_url(@draft_version), params: { draft_version: {} }, as: :json
    assert_response :success
  end

  test "should destroy draft_version" do
    assert_difference("DraftVersion.count", -1) do
      delete draft_version_url(@draft_version), as: :json
    end

    assert_response :no_content
  end
end

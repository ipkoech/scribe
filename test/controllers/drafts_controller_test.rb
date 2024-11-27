require "test_helper"

class DraftsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @draft = drafts(:one)
  end

  test "should get index" do
    get drafts_url, as: :json
    assert_response :success
  end

  test "should create draft" do
    assert_difference("Draft.count") do
      post drafts_url, params: { draft: {} }, as: :json
    end

    assert_response :created
  end

  test "should show draft" do
    get draft_url(@draft), as: :json
    assert_response :success
  end

  test "should update draft" do
    patch draft_url(@draft), params: { draft: {} }, as: :json
    assert_response :success
  end

  test "should destroy draft" do
    assert_difference("Draft.count", -1) do
      delete draft_url(@draft), as: :json
    end

    assert_response :no_content
  end
end

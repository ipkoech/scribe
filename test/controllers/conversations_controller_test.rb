require "test_helper"

class ConversationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @conversation = conversations(:one)
  end

  test "should get index" do
    get conversations_url, as: :json
    assert_response :success
  end

  test "should create conversation" do
    assert_difference("Conversation.count") do
      post conversations_url, params: { conversation: { archived: @conversation.archived, title: @conversation.title, user_id: @conversation.user_id } }, as: :json
    end

    assert_response :created
  end

  test "should show conversation" do
    get conversation_url(@conversation), as: :json
    assert_response :success
  end

  test "should update conversation" do
    patch conversation_url(@conversation), params: { conversation: { archived: @conversation.archived, title: @conversation.title, user_id: @conversation.user_id } }, as: :json
    assert_response :success
  end

  test "should destroy conversation" do
    assert_difference("Conversation.count", -1) do
      delete conversation_url(@conversation), as: :json
    end

    assert_response :no_content
  end
end

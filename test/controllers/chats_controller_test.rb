require "test_helper"

class ChatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @chat = chats(:one)
  end

  test "should get index" do
    get chats_url, as: :json
    assert_response :success
  end

  test "should create chat" do
    assert_difference("Chat.count") do
      post chats_url, params: { chat: { bot_reply: @chat.bot_reply, conversation_id: @chat.conversation_id, disliked: @chat.disliked, highlighted_text: @chat.highlighted_text, liked: @chat.liked, reply_to_highlight: @chat.reply_to_highlight, role: @chat.role, user_input: @chat.user_input } }, as: :json
    end

    assert_response :created
  end

  test "should show chat" do
    get chat_url(@chat), as: :json
    assert_response :success
  end

  test "should update chat" do
    patch chat_url(@chat), params: { chat: { bot_reply: @chat.bot_reply, conversation_id: @chat.conversation_id, disliked: @chat.disliked, highlighted_text: @chat.highlighted_text, liked: @chat.liked, reply_to_highlight: @chat.reply_to_highlight, role: @chat.role, user_input: @chat.user_input } }, as: :json
    assert_response :success
  end

  test "should destroy chat" do
    assert_difference("Chat.count", -1) do
      delete chat_url(@chat), as: :json
    end

    assert_response :no_content
  end
end

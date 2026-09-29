# Elkheta: the current agent's starred messages (optionally for one conversation).
class Api::V1::Accounts::StarredMessagesController < Api::V1::Accounts::BaseController
  def index
    stars = MessageStar.where(account: Current.account, user: Current.user)
                       .includes(message: [:attachments, :sender], conversation: :contact)
                       .order(created_at: :desc)
                       .limit(200)
    if params[:conversation_id].present?
      conversation = Current.account.conversations.find_by!(display_id: params[:conversation_id])
      stars = stars.where(conversation: conversation)
    end
    render json: stars.filter_map { |star| star_payload(star) }
  end

  private

  def star_payload(star)
    message = star.message
    return if message.blank?

    {
      message_id: message.id,
      conversation_id: star.conversation.display_id,
      contact_name: star.conversation.contact&.name,
      content: message.content.to_s.first(300),
      attachment_type: message.attachments.first&.file_type,
      message_type: message.message_type,
      created_at: message.created_at.to_i,
      starred_at: star.created_at.to_i
    }
  end
end

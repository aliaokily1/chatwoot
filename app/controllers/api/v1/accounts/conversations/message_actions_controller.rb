# Elkheta: WhatsApp-style message actions — react, forward, pin (CRM only), star (personal).
class Api::V1::Accounts::Conversations::MessageActionsController < Api::V1::Accounts::Conversations::BaseController
  MAX_PINS = 3
  MAX_FORWARD_TARGETS = 5

  before_action :fetch_message

  def react
    emoji = params[:emoji].to_s
    reactions = (@message.content_attributes[:reactions] || {}).to_h.deep_stringify_keys
    if emoji.present?
      reactions['business'] = { 'emoji' => emoji, 'user_id' => Current.user.id, 'at' => Time.current.to_i }
    else
      reactions.delete('business')
    end
    @message.update!(content_attributes: @message.content_attributes.merge('reactions' => reactions))
    Elkheta::SendWhatsappReactionJob.perform_later(@message.id, emoji) if @message.source_id.present?
    render json: { reactions: reactions }
  end

  def forward
    targets = Current.account.conversations.where(display_id: Array(params[:conversation_ids]).first(MAX_FORWARD_TARGETS))
    targets.each { |target| authorize target, :show? }

    forwarded = targets.map do |target|
      Messages::MessageBuilder.new(Current.user, target, forward_params).perform
      target.display_id
    end
    render json: { forwarded_to: forwarded }
  end

  def pin
    ids = pinned_ids
    ids = ([@message.id] + ids.reject { |id| id == @message.id }).first(MAX_PINS)
    save_pins(ids)
  end

  def unpin
    save_pins(pinned_ids.reject { |id| id == @message.id })
  end

  def star
    MessageStar.find_or_create_by!(message: @message, user: Current.user) do |star|
      star.account = Current.account
      star.conversation = @conversation
    end
    head :ok
  end

  def unstar
    MessageStar.where(message: @message, user: Current.user).delete_all
    head :ok
  end

  private

  def fetch_message
    @message = @conversation.messages.find(params[:message_id])
  end

  def pinned_ids
    Array(@conversation.additional_attributes&.dig('pinned_message_ids')).map(&:to_i)
  end

  def save_pins(ids)
    @conversation.update!(additional_attributes: (@conversation.additional_attributes || {}).merge('pinned_message_ids' => ids))
    render json: { pinned_message_ids: ids }
  end

  # A new outgoing message with the same text and copies of the attachments
  def forward_params
    attachments = @message.attachments.filter_map do |attachment|
      next unless attachment.file.attached?

      ActiveStorage::Blob.create_and_upload!(io: StringIO.new(attachment.file.download),
                                             filename: attachment.file.filename.to_s,
                                             content_type: attachment.file.content_type).signed_id
    end
    attributes = { forwarded: true }
    attributes[:is_sticker] = true if @message.content_attributes[:is_sticker]
    ActionController::Parameters.new(
      message_type: 'outgoing', private: false, content: @message.content,
      attachments: attachments, content_attributes: attributes
    )
  end
end

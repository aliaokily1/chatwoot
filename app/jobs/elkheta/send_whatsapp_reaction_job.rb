# Elkheta: deliver an agent's reaction to the student's WhatsApp (Cloud API only).
class Elkheta::SendWhatsappReactionJob < ApplicationJob
  queue_as :high

  def perform(message_id, emoji)
    message = Message.find_by(id: message_id)
    return if message.blank? || message.source_id.blank?

    channel = message.inbox.channel
    return unless channel.is_a?(Channel::Whatsapp) && channel.provider == 'whatsapp_cloud'

    response = channel.provider_service.send_reaction(message.conversation.contact_inbox.source_id, message.source_id, emoji)
    return if response.success?

    Rails.logger.warn "[ELKHETA_REACTION] message=#{message_id} failed: #{response.code} #{response.body.to_s.first(300)}"
  end
end

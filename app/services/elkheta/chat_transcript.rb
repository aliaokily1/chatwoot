# Elkheta: plain-text transcript of a chat, in WhatsApp's "Export chat" style
# ("29/09/2026, 10:42 AM - Ahmed: message"). Also the input for the AI summary.
class Elkheta::ChatTranscript
  TIME_FORMAT = '%d/%m/%Y, %I:%M %p'.freeze
  MEDIA_LABELS = {
    'image' => 'image',
    'audio' => 'voice note',
    'video' => 'video',
    'file' => 'document',
    'location' => 'location',
    'contact' => 'contact card'
  }.freeze

  # roles: true labels each line "Student"/"Admin"/"Internal note" (for the AI) instead of names only
  def initialize(conversation, time_zone: nil, include_notes: false, last: nil, roles: false)
    @conversation = conversation
    @zone = ActiveSupport::TimeZone[time_zone.to_s] || Time.zone
    @include_notes = include_notes
    @last = last
    @roles = roles
  end

  def lines
    messages.filter_map { |message| line_for(message) }
  end

  def to_s
    lines.join("\n")
  end

  def header
    contact = @conversation.contact
    phone = contact.phone_number.present? ? " (#{contact.phone_number})" : ''
    "Elkheta Class — chat with #{contact.name}#{phone} — exported #{Time.current.in_time_zone(@zone).strftime(TIME_FORMAT)}"
  end

  private

  def messages
    scope = @conversation.messages
                         .where(message_type: %i[incoming outgoing template])
                         .includes(:sender, attachments: { file_attachment: :blob })
    scope = scope.where(private: false) unless @include_notes
    return scope.reorder(created_at: :asc) if @last.blank?

    scope.reorder(created_at: :desc).limit(@last).to_a.reverse
  end

  def line_for(message)
    text = body_for(message)
    return if text.blank?

    "#{message.created_at.in_time_zone(@zone).strftime(TIME_FORMAT)} - #{author_for(message)}: #{text}"
  end

  def author_for(message)
    name = message.incoming? ? @conversation.contact.name : message.sender&.name
    return name.presence || 'Admin' unless @roles
    return "Internal note by #{name.presence || 'Admin'}" if message.private?
    return "Student (#{name})" if message.incoming?

    name.present? ? "Admin (#{name})" : 'Admin'
  end

  def body_for(message)
    attrs = message.content_attributes || {}
    return 'This message was deleted' if attrs['deleted']

    parts = []
    parts << '(forwarded)' if attrs['forwarded']
    parts << '[sticker]' if attrs['is_sticker']
    parts << message.content if message.content.present?
    message.attachments.each { |attachment| parts << attachment_label(attachment) } unless attrs['is_sticker']
    parts.join(' ')
  end

  def attachment_label(attachment)
    label = MEDIA_LABELS.fetch(attachment.file_type.to_s, 'file')
    return "[#{label}]" if @roles || attachment.file_url.blank?

    "[#{label}] #{attachment.file_url}"
  end
end

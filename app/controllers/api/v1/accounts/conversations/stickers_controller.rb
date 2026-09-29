# Elkheta: send a library sticker into a conversation as a WhatsApp sticker message.
class Api::V1::Accounts::Conversations::StickersController < Api::V1::Accounts::Conversations::BaseController
  def create
    sticker = Sticker.where(account: Current.account).find(params[:sticker_id])
    # Copy the file so deleting this message later never removes the library sticker
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new(sticker.image.download),
                                                  filename: sticker.image.filename.to_s,
                                                  content_type: sticker.image.content_type)
    message_params = ActionController::Parameters.new(
      message_type: 'outgoing',
      private: false,
      attachments: [blob.signed_id],
      content_attributes: { is_sticker: true }
    )
    message = Messages::MessageBuilder.new(Current.user, @conversation, message_params).perform
    sticker.mark_used!
    render json: { id: message.id }
  end
end

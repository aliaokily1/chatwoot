# Elkheta: the account's WhatsApp sticker library.
class Api::V1::Accounts::StickersController < Api::V1::Accounts::BaseController
  ALLOWED_TYPES = %w[image/webp].freeze

  before_action :fetch_sticker, only: [:destroy, :favorite, :unfavorite]

  def index
    @stickers = stickers_scope.with_attached_image.library_order.limit(500)
    @favorite_ids = favorite_ids_for(@stickers.map(&:id))
  end

  def create
    file = params.require(:image)
    return render_invalid unless ALLOWED_TYPES.include?(file.content_type) && file.size <= Sticker::MAX_BYTES

    blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: file.original_filename.presence || 'sticker.webp',
                                                  content_type: file.content_type)
    @sticker = stickers_scope.find_by(checksum: blob.checksum)
    if @sticker
      blob.purge_later
    else
      @sticker = stickers_scope.new(user: Current.user, name: params[:name], source: :uploaded, checksum: blob.checksum)
      @sticker.image.attach(blob)
      @sticker.save!
    end
    @favorite_ids = favorite_ids_for([@sticker.id])
    render :show
  end

  def destroy
    return head :forbidden unless can_delete?

    @sticker.destroy!
    head :no_content
  end

  def favorite
    StickerFavorite.find_or_create_by!(sticker: @sticker, user: Current.user)
    head :ok
  end

  def unfavorite
    StickerFavorite.where(sticker: @sticker, user: Current.user).delete_all
    head :ok
  end

  private

  def stickers_scope
    Sticker.where(account: Current.account)
  end

  def fetch_sticker
    @sticker = stickers_scope.find(params[:id])
  end

  def favorite_ids_for(ids)
    StickerFavorite.where(user: Current.user, sticker_id: ids).pluck(:sticker_id).to_set
  end

  def can_delete?
    Current.account_user&.administrator? || @sticker.user_id == Current.user.id
  end

  def render_invalid
    render json: { error: I18n.t('errors.stickers.invalid', default: 'A sticker must be a WebP image up to 500 KB') },
           status: :unprocessable_entity
  end
end

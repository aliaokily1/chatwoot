# Elkheta: personal WhatsApp-style chat lists (Favourites + custom lists) for the current agent.
class Api::V1::Accounts::ConversationListsController < Api::V1::Accounts::BaseController
  before_action :fetch_conversation_list, except: [:index, :create]
  before_action :fetch_conversation, only: [:add_conversation, :remove_conversation]

  def index
    ConversationList.favourites_for(Current.account, Current.user)
    @conversation_lists = lists_scope.ordered
  end

  def create
    @conversation_list = lists_scope.create!(name: params.require(:name), position: lists_scope.maximum(:position).to_i + 1)
    render :show
  end

  def update
    @conversation_list.update!(name: params.require(:name)) unless @conversation_list.favourites?
    render :show
  end

  def destroy
    return head :unprocessable_entity if @conversation_list.favourites?

    @conversation_list.destroy!
    head :no_content
  end

  def add_conversation
    @conversation_list.conversation_list_items.find_or_create_by!(conversation: @conversation)
    render :show
  end

  def remove_conversation
    @conversation_list.conversation_list_items.where(conversation: @conversation).delete_all
    render :show
  end

  private

  def lists_scope
    ConversationList.where(account: Current.account, user: Current.user)
  end

  def fetch_conversation_list
    @conversation_list = lists_scope.find(params[:id])
  end

  def fetch_conversation
    @conversation = Current.account.conversations.find_by!(display_id: params[:conversation_id])
    authorize @conversation, :show?
  end
end

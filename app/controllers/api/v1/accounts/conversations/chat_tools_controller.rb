# Elkheta: chat ⋮ menu tools — Export chat (WhatsApp-style .txt) and Summarize with AI.
class Api::V1::Accounts::Conversations::ChatToolsController < Api::V1::Accounts::Conversations::BaseController
  def export
    transcript = Elkheta::ChatTranscript.new(@conversation, time_zone: params[:time_zone])
    send_data "#{transcript.header}\n\n#{transcript}\n",
              filename: "Elkheta chat - #{@conversation.contact.name.to_s.gsub(/[^[:alnum:] _-]/, '').strip.presence || @conversation.display_id}.txt",
              type: 'text/plain; charset=utf-8'
  end

  def summary
    result = Elkheta::ChatSummaryService.new(@conversation, locale: params[:locale], time_zone: params[:time_zone]).perform
    render json: result
  rescue Elkheta::ChatSummaryService::NotConfiguredError
    render json: { error: 'not_configured' }, status: :unprocessable_entity
  rescue Elkheta::ChatSummaryService::Error, HTTParty::Error, Net::OpenTimeout, Net::ReadTimeout => e
    render json: { error: e.message }, status: :bad_gateway
  end
end

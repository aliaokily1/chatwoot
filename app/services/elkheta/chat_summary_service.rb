# Elkheta: AI summary of a chat for the Admin — what the student said, what the Admin said,
# what was agreed and what to focus on next. Uses the Claude API (ANTHROPIC_API_KEY).
class Elkheta::ChatSummaryService
  API_URL = 'https://api.anthropic.com/v1/messages'.freeze
  DEFAULT_MODEL = 'claude-sonnet-5'.freeze
  MAX_MESSAGES = 300
  MAX_CHARS = 60_000
  CACHE_TTL = 7.days
  KEYS = %w[overview student_said admin_said agreed focus_next].freeze

  class NotConfiguredError < StandardError; end
  class Error < StandardError; end

  SUMMARY_TOOL = {
    name: 'chat_summary',
    description: 'Record the structured summary of the chat.',
    input_schema: {
      type: 'object',
      properties: {
        overview: { type: 'string', description: 'One or two sentences: what the chat is about and where it stands now.' },
        student_said: { type: 'array', items: { type: 'string' },
                        description: 'Key points the student (or parent) said: problems, questions, feelings, promises.' },
        admin_said: { type: 'array', items: { type: 'string' }, description: 'Key points the Admin said, explained or advised.' },
        agreed: { type: 'array', items: { type: 'string' },
                  description: 'What both sides agreed on: plans, lessons, deadlines, next steps. Empty if nothing was agreed.' },
        focus_next: { type: 'array', items: { type: 'string' },
                      description: 'What the Admin should focus on or follow up next, most important first.' }
      },
      required: KEYS
    }
  }.freeze

  def initialize(conversation, locale: 'en', time_zone: nil)
    @conversation = conversation
    @locale = locale.to_s.start_with?('ar') ? 'ar' : 'en'
    @time_zone = time_zone
  end

  def perform
    raise NotConfiguredError if api_key.blank?

    last_message = @conversation.messages.where(message_type: %i[incoming outgoing template]).reorder(:created_at).last
    return empty_summary if last_message.blank?

    Rails.cache.fetch(cache_key(last_message), expires_in: CACHE_TTL) { request_summary }
  end

  private

  def request_summary
    response = HTTParty.post(API_URL, headers: headers, body: payload.to_json, timeout: 90)
    body = response.parsed_response.is_a?(Hash) ? response.parsed_response : {}
    raise Error, body.dig('error', 'message') || "AI request failed (#{response.code})" unless response.success?

    tool_use = Array(body['content']).find { |block| block['type'] == 'tool_use' }
    raise Error, 'AI returned no summary' if tool_use.blank?

    tool_use['input'].slice(*KEYS)
  end

  def payload
    {
      model: ENV.fetch('ELKHETA_AI_MODEL', DEFAULT_MODEL),
      max_tokens: 2000,
      system: system_prompt,
      tools: [SUMMARY_TOOL],
      tool_choice: { type: 'tool', name: 'chat_summary' },
      messages: [{ role: 'user', content: "Summarise this chat:\n\n#{transcript}" }]
    }
  end

  def system_prompt
    <<~PROMPT
      You summarise WhatsApp chats for Elkheta Class, an online learning platform. An Admin (a supervisor who follows up
      with students on their studies) talks with a student, or sometimes a student's parent.
      Write the summary for the Admin, so she can pick up the conversation in a few seconds.
      - Short bullet points with the real facts: subjects, lessons, dates, numbers, problems, promises.
      - Only what is in the chat. Never invent or assume.
      - Lines marked "Internal note" are the Admin's private notes: use them as context.
      - [voice note], [image] etc. are media you can't see; mention them only if they matter.
      - Write in the main language of the chat (an Egyptian Arabic chat gets simple Egyptian Arabic).
        If that isn't clear, write in #{@locale == 'ar' ? 'Arabic' : 'English'}.
    PROMPT
  end

  def transcript
    text = Elkheta::ChatTranscript.new(@conversation, time_zone: @time_zone, include_notes: true,
                                                      last: MAX_MESSAGES, roles: true).to_s
    text.length > MAX_CHARS ? text.last(MAX_CHARS) : text
  end

  def headers
    { 'x-api-key' => api_key, 'anthropic-version' => '2023-06-01', 'content-type' => 'application/json' }
  end

  def api_key
    ENV.fetch('ANTHROPIC_API_KEY', nil)
  end

  def cache_key(last_message)
    "elkheta:chat_summary:#{@conversation.id}:#{last_message.id}:#{last_message.updated_at.to_i}:#{@locale}"
  end

  def empty_summary
    { 'overview' => '', 'student_said' => [], 'admin_said' => [], 'agreed' => [], 'focus_next' => [] }
  end
end

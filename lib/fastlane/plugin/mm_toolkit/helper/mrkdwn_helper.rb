# frozen_string_literal: true

# Forked from https://github.com/BlazingBBQ/SlackMrkdwn
require "redcarpet"

class Mrkdwn < Redcarpet::Render::Base
  class << self
    def from(markdown)
      renderer = Mrkdwn.new
      Redcarpet::Markdown.new(renderer, strikethrough: true, underline: true, fenced_code_blocks: true).render(markdown)
    end
  end

  # Methods where the first argument is the text content
  [
    # block-level calls
    :block_html,

    :autolink,
    :raw_html,

    :table, :table_row, :table_cell,

    :superscript, :highlight,

    # footnotes
    :footnotes, :footnote_def, :footnote_ref,

    :hrule,

    # low level rendering
    :entity, :normal_text,

    :doc_header, :doc_footer,
  ].each do |method|
    define_method method do |*args|
      args.first
    end
  end

  # Encode Slack restricted characters. Exclude user or group mentions from encoding.
  def preprocess(content)
    content
      .gsub("&", "&amp;")
      .split(/ /) # Done with regex so it doesn't remove newlines
      .map { |s| /<([@!]|users).+>/.match?(s) ? s : s.gsub("<", "&lt;").gsub(">", "&gt;") } # Escape sequences which are not user mentions
      .join(" ")
  end

  def postprocess(content)
    content.rstrip
  end

  # ~~strikethrough~~
  def strikethrough(content)
    "~#{content}~"
  end

  # _italic_
  def underline(content)
    "_#{content}_"
  end

  # *italic*
  def emphasis(content)
    "_#{content}_"
  end

  # **bold**
  def double_emphasis(content)
    "*#{content}*"
  end

  # ***bold and italic***
  def triple_emphasis(content)
    "*_#{content}_*"
  end

  # ``` code block ```
  def block_code(content, _language)
    "```\n#{content}```\n\n"
  end

  # > quote
  def block_quote(content)
    "&gt; #{content}"
  end

  # `code`
  def codespan(content)
    "`#{content}`"
  end

  # links
  def link(link, _title, content)
    "<#{link}|#{content}>"
  end

  # list. Called when all list items have been consumed
  def list(entries, style)
    entries = format_list(entries, style)
    remember_last_list_entries(entries)
    entries
  end

  # list item
  def list_item(entry, _style)
    if @last_entries && entry.end_with?(@last_entries)
      entry = indent_list_items(entry)
      @last_entries = nil
    end
    entry
  end

  # ![](image)
  def image(link, _title, _content)
    link
  end

  def paragraph(text)
    pre_spacing = @last_entries ? "\n" : nil
    clear_last_list_entries
    "#{pre_spacing}#{text}\n\n"
  end

  # # Header
  def header(text, _header_level)
    "*#{text}*\n"
  end

  def linebreak
    "\n"
  end

  private

  def format_list(entries, style)
    case style
    when :ordered
      number_list(entries)
    when :unordered
      add_dashes(entries)
    end
  end

  def add_dashes(entries)
    entries.gsub(/^(\S+.*)$/, '- \1')
  end

  def number_list(entries)
    count = 0
    entries.gsub(/^(\S+.*)$/) do
      match = Regexp.last_match
      count += 1
      "#{count}. #{match[0]}"
    end
  end

  def remember_last_list_entries(entries)
    @last_entries = entries
  end

  def clear_last_list_entries
    @last_entries = nil
  end

  def nest_list_entries(entries)
    entries.gsub(/^(.+)$/, '   \1')
  end

  def indent_list_items(entry)
    entry.gsub(@last_entries, nest_list_entries(@last_entries))
  end
end

module Fastlane
  module Actions
    class MrkdwnHelper
      def self.format_mrkdwn(text)
        Mrkdwn.from(text)
      end
    end
  end
end

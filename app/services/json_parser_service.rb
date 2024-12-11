require "json"

class JsonParserService
  def self.parse(response_body)
    # Apply heuristics in a sequence until something parses
    attempts = [
      :parse_as_is,
      :escape_newlines_in_strings,
      :fix_unbalanced_brackets,
      :remove_trailing_commas,
      :remove_control_characters,
    ]

    result = nil
    json_candidate = response_body.dup

    attempts.each do |attempt|
      # If we can parse successfully, return the parsed Hash/Array
      parsed = attempt_parse(json_candidate)
      if parsed
        # Once parsed, return the parsed object as a Hash or Array
        # The content field should now be a Ruby string with actual newline chars,
        # which can be passed to a Markdown editor as-is.
        return parsed
      end

      # If parsing failed, apply the heuristic and try again
      json_candidate = send(attempt, json_candidate)
    end

    # If all attempts fail, return nil or the original response_body
    nil
  end

  private

  # Attempt a direct parse
  def self.attempt_parse(json_str)
    parsed = JSON.parse(json_str)
    (parsed.is_a?(Hash) || parsed.is_a?(Array)) ? parsed : nil
  rescue JSON::ParserError
    nil
  end

  # Heuristic 1: No changes, just return as-is
  def self.parse_as_is(json_str)
    json_str
  end

  # Heuristic 2: Escape newlines within strings
  def self.escape_newlines_in_strings(json_str)
    inside_string = false
    escaped = false
    result = []

    json_str.each_char do |char|
      if inside_string
        if escaped
          # Previous char was a backslash, just add current char
          result << char
          escaped = false
        else
          case char
          when '\\'
            result << char
            escaped = true
          when '"'
            result << char
            inside_string = false
          when "\n"
            # Replace literal newline with escaped \n
            result << '\\' << "n"
          else
            result << char
          end
        end
      else
        # Outside string
        case char
        when '"'
          inside_string = true
          result << char
        else
          result << char
        end
      end
    end

    result.join
  end

  # Heuristic 3: Fix common unbalanced brackets at the end
  def self.fix_unbalanced_brackets(json_str)
    trimmed = json_str.strip
    # Count braces and brackets
    open_braces = trimmed.count("{")
    close_braces = trimmed.count("}")
    open_brackets = trimmed.count("[")
    close_brackets = trimmed.count("]")

    # Add closing brace/bracket if needed
    trimmed << "}" if open_braces > close_braces
    trimmed << "]" if open_brackets > close_brackets
    trimmed
  end

  # Heuristic 4: Remove trailing commas before closing brackets/braces
  def self.remove_trailing_commas(json_str)
    json_str.gsub(/,(\s*[\}\]])/, '\\1')
  end

  # Heuristic 5: Remove non-standard control characters
  def self.remove_control_characters(json_str)
    # Keep printable chars plus tab(9), newline(10), carriage return(13).
    # Remove other control chars.
    json_str.chars.map do |c|
      if c.ord == 9 || c.ord == 10 || c.ord == 13 || c.ord >= 32
        c
      else
        ""
      end
    end.join
  end
end

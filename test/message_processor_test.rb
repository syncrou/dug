require 'test_helper'

class MessageProcessorTest < MiniTest::Test

  class BaseMessage
    def id
      "123abc"
    end

    def headers
      { "Date" => "Some date", "From" => "Someone", "Subject" => "Some subject" }
    end

    def organization
      "chrisarcand"
    end

    def repository
      "dug"
    end

    def reason
      nil
    end

    def indicates_merged?
      false
    end

    def indicates_closed?
      false
    end

    def indicates_reopened?
      false
    end
  end

  class MentionedMessage < BaseMessage
    def reason
      "mention"
    end
  end

  class MergedMessage < BaseMessage
    def indicates_merged?
      true
    end
  end

  class ClosedMessage < BaseMessage
    def indicates_closed?
      true
    end
  end

  class ReopenedMessage < BaseMessage
    def indicates_reopened?
      true
    end
  end

  class MultipleRemotesPossible < BaseMessage
    def repository
      "dotfiles"
    end
  end

  class MultipleRemotesPossibleOtherMatch < MultipleRemotesPossible
    def organization
      "juliancheal"
    end
  end

  class MultipleRemotesButNoMatch < MultipleRemotesPossible
    def organization
      "jphenow"
    end
  end

  def setup
    Dug.configure do |config|
      config.rule_file = File.expand_path("../configurator/rule_file_fixtures/valid_rule_file.yml", __FILE__)
    end

    @mock_servicer = MiniTest::Mock.new
  end

  def test_correct_mentioned_labels
    @mock_message  = MentionedMessage.new

    Dug::NotificationDecorator.stub :new, @mock_message do
      @mock_servicer.expect(:get_user_message, nil, [String, String])
      @mock_servicer.expect(:add_labels_by_name, nil, [@mock_message, ["GitHub", "Chris Arcand", "dug", "Mentioned"]])
      @mock_servicer.expect(:remove_labels_by_name, nil, [@mock_message, ["GitHub/Unprocessed"], entire_thread: false])

      Dug::MessageProcessor.new("dummy_id", @mock_servicer).execute
      @mock_servicer.verify
    end
  end

  def test_multiple_remotes_possible_1
    @mock_message = MultipleRemotesPossible.new

    Dug::NotificationDecorator.stub :new, @mock_message do
      @mock_servicer.expect(:get_user_message, nil, [String, String])
      @mock_servicer.expect(:add_labels_by_name, nil, [@mock_message, ["GitHub", "Chris Arcand", "My dotfiles"]])
      @mock_servicer.expect(:remove_labels_by_name, nil, [@mock_message, ["GitHub/Unprocessed"], entire_thread: false])

      Dug::MessageProcessor.new("dummy_id", @mock_servicer).execute
      @mock_servicer.verify
    end
  end

  def test_multiple_remotes_possible_2
    @mock_message = MultipleRemotesPossibleOtherMatch.new

    Dug::NotificationDecorator.stub :new, @mock_message do
      @mock_servicer.expect(:get_user_message, nil, [String, String])
      @mock_servicer.expect(:add_labels_by_name, nil, [@mock_message, ["GitHub", "Julian's dotfiles"]])
      @mock_servicer.expect(:remove_labels_by_name, nil, [@mock_message, ["GitHub/Unprocessed"], entire_thread: false])

      Dug::MessageProcessor.new("dummy_id", @mock_servicer).execute
      @mock_servicer.verify
    end
  end

  def test_multiple_remotes_but_no_rule
    @mock_message = MultipleRemotesButNoMatch.new

    Dug::NotificationDecorator.stub :new, @mock_message do
      @mock_servicer.expect(:get_user_message, nil, [String, String])
      @mock_servicer.expect(:add_labels_by_name, nil, [@mock_message, ["GitHub"]])
      @mock_servicer.expect(:remove_labels_by_name, nil, [@mock_message, ["GitHub/Unprocessed"], entire_thread: false])

      Dug::MessageProcessor.new("dummy_id", @mock_servicer).execute
      @mock_servicer.verify
    end
  end

  def test_merged_message
    @mock_message = MergedMessage.new


    Dug::NotificationDecorator.stub :new, @mock_message do
      @mock_servicer.expect(:get_user_message, nil, [String, String])
      @mock_servicer.expect(:add_labels_by_name, nil, [@mock_message, ["GitHub", "Chris Arcand", "dug", "Merged"]])
      @mock_servicer.expect(:remove_labels_by_name, nil, [@mock_message, ["GitHub/Unprocessed"], entire_thread: false])

      Dug::MessageProcessor.new("dummy_id", @mock_servicer).execute
      @mock_servicer.verify
    end
  end

  def test_closed_message
    @mock_message = ClosedMessage.new


    Dug::NotificationDecorator.stub :new, @mock_message do
      @mock_servicer.expect(:get_user_message, nil, [String, String])
      @mock_servicer.expect(:add_labels_by_name, nil, [@mock_message, ["GitHub", "Chris Arcand", "dug", "Closed"]])
      @mock_servicer.expect(:remove_labels_by_name, nil, [@mock_message, ["GitHub/Unprocessed"], entire_thread: false])

      Dug::MessageProcessor.new("dummy_id", @mock_servicer).execute
      @mock_servicer.verify
    end
  end

  def test_reopened_message
    @mock_message = ReopenedMessage.new


    Dug::NotificationDecorator.stub :new, @mock_message do
      @mock_servicer.expect(:get_user_message, nil, [String, String])
      @mock_servicer.expect(:add_labels_by_name, nil, [@mock_message, ["GitHub", "Chris Arcand", "dug", "Reopened"]])
      @mock_servicer.expect(:remove_labels_by_name, nil, [@mock_message, ["GitHub/Unprocessed", "Closed"], entire_thread: true])

      Dug::MessageProcessor.new("dummy_id", @mock_servicer).execute
      @mock_servicer.verify
    end
  end
end

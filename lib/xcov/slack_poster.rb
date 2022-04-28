
module Xcov
  class SlackPoster

    def run(report)
      return if Xcov.config[:skip_slack]
      return if Xcov.config[:slack_url].to_s.empty?

      require 'slack-notifier'

      url = Xcov.config[:slack_url]
      username = Xcov.config[:slack_username]
      channel = Xcov.config[:slack_channel]
      if channel.to_s.length > 0
        channel = ('#' + channel) unless ['#', '@'].include?(channel[0])
      end

      notifier = Slack::Notifier.new(url, channel: channel, username: username)

      attachments = []

      slackCustomTargetName = Slack::Notifier::Util::LinkFormatter.format(Xcov.config[:slack_custom_target_name])
      if slackCustomTargetName.empty?
        report.targets.each do |target|
          attachments << {
            text: "#{target.name}: #{target.displayable_coverage}",
            color: target.coverage_color,
            short: true
          }
        end
      else
        report.targets.each do |target|
          attachments << {
            text: "#{slackCustomTargetName}: #{target.displayable_coverage}",
            color: target.coverage_color,
            short: true
          }
        end
      end

      begin
        message = Slack::Notifier::Util::LinkFormatter.format(Xcov.config[:slack_message])
        slackIconUrl = Slack::Notifier::Util::LinkFormatter.format(Xcov.config[:slack_icon_url])
        if slackIconUrl.empty?
          results = notifier.ping(
            message,
            icon_url: 'https://s3-eu-west-1.amazonaws.com/fastlane.tools/fastlane.png',
            attachments: attachments
          )
        else
          results = notifier.ping(
            message,
            icon_url: slackIconUrl,
            attachments: attachments
          )
        end
        if !results.first.nil? && results.first.code.to_i == 200
          UI.message 'Successfully sent Slack notification'.green
        else
          UI.error "xcov failed to upload results to slack"
        end

      rescue Exception => e
        UI.error "xcov failed to upload results to slack. error: #{e.to_s}"
      end
    end

  end
end

ActiveSupport::Notifications.subscribe "index.event" do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    Honeybadger.notify("This report is from the index action")
end

ActiveSupport::Notifications.subscribe 'process_action.action_controller' do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    Rails.logger.info "Event received: #{event}"
    if event.duration > 2000
        Honeybadger.notify("This action has lasted more than 2s")
    end
end

## Introduction
This tutorial explains how to report data of rails application usage based critical events. These events are subjective but we will look at a more general type of event namely an endpoint that takes too long to load.

We will report the events using Honeybadger. Honeybadger, as we will see, is easy to setup and has many features that allow.

## Setting up Honeybadger
First, we will need a Rails application to plug Honeybadger into. Conveniently, I have created a template that setups a quick rails application with simple authentication and user data seeded to a database. To use it, do the following
- Download this rails template gist https://gist.github.com/Sylvance/5c7d5db8ce8609fa16403e74255dee39
- Change into the directory this gist is in.
- Then run `rails new your_app_name --database=postgresql -m ./template.rb` to create the rails app with a postgres database. When asked to override stuff say Yes.

There's that. We now have a full Rails app which is simple but complex enough to show where Honeybadger shines.

Sign up for a trial account at Honeybadger. Then choose rails as the framework you will use. Follow the instructions shown for Rails then click "Complete Setup". I will just repeat those instructions just in case needed. Now in your `Gemfile` add `gem 'honeybadger', '~> 4.0'` then run `bundle install`.  Next use your `apikey` to run this command; `bundle exec honeybadger install [apikey]`. This command will generate a `honeybadger.yml` file under the config directory then sends a test notification to your Honeybadger errors dashboard which will look something like below.

![Alt Text](https://dev-to-uploads.s3.amazonaws.com/i/oxzyvuggmdwj8fih8af2.png)

Congrats. You've setup  Honeybadger and plugged it into your Rails app.

## Reporting using Honeybadger.notify
Reporting using Honeybadger is just a call away. But first we shall add this to our configuration file, `config/honeybadger.yml`;

```yaml
env: 'production'
```

By default, Honeybadger suppresses reports sent on a development environment. By adding the line above we are able to send reports to the Honeybadger account so that they are displayed on the dashboard.

Now we will use `Honeybadger.notify` to report everytime any endpoint is hit in our app. Add the following to `application_controller.rb`;

```ruby
before_action do
    Honeybadger.notify("Reporting live from an arbitrary endpoint!")        
end
```

If we run the server using `rails s` then go to `http://localhost:3000` within the application we will see this in the terminal;

![Alt Text](https://dev-to-uploads.s3.amazonaws.com/i/urkjk91fwu5e0ushj29q.png)


If we look at the Honeybadger errors dashboard we will see this;
![Alt Text](https://dev-to-uploads.s3.amazonaws.com/i/ly1er1956ykgkniwpjdl.png)

That's great! We have made our first report using Honeybadger. However, it is not that helpful since it has no insights as to what problem might have occurred. Next let's build on this by providing more insights.

## Using Honeybadger.context to give more context to error reports
To give context as to how an error occurred Honeybadger gives you the `context` method to help with this. For instance, we can use the context method to include data about the use associated with a report.
To do this in our application, within the `application_controller.rb` replace the previous code with;

```ruby
before_action :build_context

# place below authenticate_request method
def build_context
    Honeybadger.context({
        user_id: current_user.id,
        user_email: current_user.email
    })
end
```

Now whenever a report is sent using Honeybadger it will contain the details of the user that sent it. We will still need to call `Honeybadger.notify` to do this we can add this line to the `app/controllers/users_controller.rb` within the `index` action:
```ruby
def index
    @users = User.all
    ActiveSupport::Notifications.instrument "index.event"
end
```
Everytime this action is executed an `index.event` event is published. We will need a subscriber in order to use this to send Honeybadger reports. Create a new file in `config/initializers` and call it `events.rb`. Insert this:
```ruby
ActiveSupport::Notifications.subscribe "index.event" do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    Honeybadger.notify("This report is from the index action")
end
```
This subscriber listens to our custom "index.event" event and triggers Honeybadger to send a report. We will need to add this in the `app/controller/sessions_controller.rb`;
```ruby
skip_before_action :build_context, only: [:new, :create]
```
This should skip building the context when logging in

Now to test how context works, restart the server with `rails s` and go to `http://localhost:3000/signup` and create a new user then login at `http://localhost:3000/login`. Then go to `http://localhost:3000/users`. A report will be sent from the index action in `app/controllers/users_controller.rb`. This is how context will look like in the Honeybadger dashboard with the user details in it.
![Alt Text](https://dev-to-uploads.s3.amazonaws.com/i/z0dwybhbwg16sw19i11l.png)

## Using Honeybadger with the ActiveSupport instrumentation API
Let's say we want to send a report every time an endpoint request takes longer than 2 seconds to execute. To do this, we can leverage the ActiveSupport instrumentation API which acts in publisher-subscriber type of way.

Inside `events.rb` insert this code:
```ruby
ActiveSupport::Notifications.subscribe 'process_action.action_controller' do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    Rails.logger.info "Event received: #{event}"
    if event.duration > 2000
        Honeybadger.notify("This action has lasted more than 2s")
    end
end
```

Above we have a subscriber that 'listens' to the `process_action.action_controller` event in Rails. These events occur when a controller action is executed. When the event occurs, we then check for how long it took using `event.duration`. If the duration is longer than 2s we send a report using `Honeybadger.notify`.

Now to test this out let us go to `app/controllers/users_controller.rb` and add code to cause a 3-second delay within the `show` action as shown:

```ruby
def show
    sleep 3
end
```

This action is guaranteed to execute longer than 2 seconds every time and thereby sending a report to Honeybadger. Now restart the server with `rails s` and go to `http://localhost:3000/users`. Pick any user and click on their respective `Show` link. This will execute for 3 seconds or longer and a report will be seen in the Honeybadger errors dashboard as shown below.
![Alt Text](https://dev-to-uploads.s3.amazonaws.com/i/iruvglkt3bz0c7kblotz.png)

## Using Honeybadger with breadcrumbs
Breadcrumbs give us the ability to see statements that have been executed leading up to an error. This is powerful when debugging an issue that has been reported by Honeybadger. We will update the Honeybadger yaml config to enable breadcrumbs:
```yaml
breadcrumbs:
  enabled: true
```
And that is all you need to get breadcrumbs running for Honeybadger. To test it out, restart the server then go to `http://localhost:3000/users`. Pick any user and click on their respective `Show` link. This will trigger a report to be sent. In the dashboard the breadcrumb will look something like this;

![Alt Text](https://dev-to-uploads.s3.amazonaws.com/i/ona2esjcuopdqr5j12m9.png)

## Conclusion
Honeybadger is an excellent tool to use for monitoring an application. It is relatively easy and quick to setup. Using it with Rails ActiveSupport gives you full control of monitoring any parts of your application. All the resulting code for this article can be found here https://github.com/Sylvance/badge-honey.

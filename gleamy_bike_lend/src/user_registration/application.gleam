import gleam/dict
import gleam/erlang/process
import gleam/io
import gleam/otp/actor
import gleam/result
import signal
import user_registration/domain

pub type UserRegistrationAggregate =
  process.Subject(
    signal.ContextMessage(
      domain.UserRegistration,
      domain.UserRegistrationCommand,
      domain.UserRegistrationEvent,
    ),
  )

pub fn create_aggregate(
  sms_sender,
  code_generator,
) -> Result(UserRegistrationAggregate, Nil) {
  let aggregate_configuration =
    signal.AggregateConfig(
      initial_state: domain.empty_registration(),
      command_handler: domain.user_registration_command_handler(code_generator),
      event_handler: domain.user_registration_event_handler(),
    )

  signal.configure(aggregate_configuration)
  |> signal.without_debug_logging
  |> signal.with_subscriber(signal.Consumer(sms_sender))
  |> signal.start()
  |> result.nil_error
}

pub fn send_sms_service(
  message: signal.ConsumerMessage(
    dict.Dict(String, String),
    domain.UserRegistrationEvent,
  ),
  state: dict.Dict(String, String),
) {
  case message {
    // Revenue report only cares about the CartPaid event
    signal.Consume(signal.Event(
      _,
      _,
      _,
      _,
      _,
      data: domain.UserRegistrationCreated(handle, number, code),
    )) -> {
      let number = domain.phone_number_to_string(number)
      let user = domain.user_handle_to_string(handle)
      io.println(
        "Dear "
        <> user
        <> " with number "
        <> number
        <> ". Please use code "
        <> code
        <> " to register at our service",
      )
      actor.continue(state |> dict.insert(user, code))
    }
    signal.GetConsumerState(s) -> {
      process.send(s, state)
      actor.continue(state)
    }
    signal.ShutdownConsumer -> actor.Stop(process.Normal)
    _ -> actor.continue(state)
  }
}

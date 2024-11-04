import birl
import gleam/dict
import gleam/erlang/process
import gleam/io
import gleam/otp/actor
import gleam/result
import signal
import user_registration/application as ua
import user_registration/domain

pub fn dead_serious_code_generator() {
  "09868766"
}

pub fn dead_searious_sms_sender(handle, code) {
  io.print("We have a code for you")
  io.debug(handle)
  io.debug(code)
}

fn full_name() {
  let assert Ok(name) = domain.full_name("Ikke", "Und Er")
  name
}

pub fn get_user_registration(
  em: ua.UserRegistrationAggregate,
  id,
) -> Result(domain.UserRegistration, String) {
  use agregat <- result.try(signal.aggregate(em, id))
  Ok(signal.get_state(agregat))
}

pub fn create_sms_sender() -> process.Subject(
  signal.ConsumerMessage(
    dict.Dict(String, String),
    domain.UserRegistrationEvent,
  ),
) {
  let assert Ok(send_sms) = actor.start(dict.new(), ua.send_sms_service)
  send_sms
}

pub fn main() {
  io.println("Hello from gleamy_bike_lend!")

  let sms_sender = create_sms_sender()

  let assert Ok(aggregate_signal) =
    ua.create_aggregate(sms_sender, dead_serious_code_generator)

  let assert Ok(handle) = domain.user_handle("Ikke")
  let assert Ok(phone_number) = domain.phone_number("0049088798723")

  let assert Ok(aggregate) = signal.create(aggregate_signal, "1")

  let _ =
    signal.handle_command(
      aggregate,
      domain.CreateUserRegistration(handle, phone_number),
    )
  let assert Error(reason) =
    signal.handle_command(aggregate, domain.VerifyPhoneNumber("WRONG!"))
  io.print("Expected the wrong code to fail! " <> reason)

  let assert Ok(_) =
    signal.handle_command(aggregate, domain.VerifyPhoneNumber("09868766"))
  let _ =
    signal.handle_command(
      aggregate,
      domain.CompleteUserRegistration(full_name()),
    )

  let final_state = get_user_registration(aggregate_signal, "1")
  io.println
  { "\n\n\n\n" }
  io.debug(final_state)
  // signal.aggregate(aggregate_signal, "1")
  // |> result.then(signal.get_state)

  let code = process.call(sms_sender, signal.GetConsumerState(_), 50)
  io.debug(code)
}

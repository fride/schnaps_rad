import signal

pub opaque type UserHandle {
  UserHandle(handle: String)
}

pub opaque type PhoneNumber {
  PhoneNumber(number: String)
}

pub opaque type FullName {
  FullName(first_name: String, last_name: String)
}

pub type VerificationCode =
  String

pub type UserRegistrationState {
  Pending
  PhoneVerified
  Completed(name: FullName)
}

pub type UserRegistration {
  UserRegistration(
    user_handle: UserHandle,
    phone_number: PhoneNumber,
    verification_code: String,
    state: UserRegistrationState,
  )
}

pub type UserRegistrationCommand {
  CreateUserRegistration(UserHandle, PhoneNumber)
  VerifyPhoneNumber(VerificationCode)
  CompleteUserRegistration(FullName)
}

pub type UserRegistrationEvent {
  UserRegistrationCreated(UserHandle, PhoneNumber, VerificationCode)
  PhoneNumberVerified
  UserRegistrationCompleted(FullName)
}

pub fn empty_registration() {
  UserRegistration(UserHandle(""), PhoneNumber(""), "", Pending)
}

//TODO validation
pub fn user_handle(handle) {
  Ok(UserHandle(handle))
}

pub fn user_handle_to_string(handle: UserHandle) {
  handle.handle
}

pub fn full_name(first, second) {
  Ok(FullName(first, second))
}

pub fn phone_number(number) {
  Ok(PhoneNumber(number))
}

pub fn phone_number_to_string(number: PhoneNumber) {
  number.number
}

// behavior
pub fn user_registration_command_handler(
  code_generator,
) -> signal.CommandHandler(
  UserRegistration,
  UserRegistrationCommand,
  UserRegistrationEvent,
) {
  fn(command: UserRegistrationCommand, user_registration: UserRegistration) {
    case command {
      CreateUserRegistration(user_handle, phone_number) -> {
        Ok([
          UserRegistrationCreated(user_handle, phone_number, code_generator()),
        ])
      }
      CompleteUserRegistration(full_name) -> {
        case user_registration.state {
          PhoneVerified -> Ok([UserRegistrationCompleted(full_name)])
          _ -> Error("Phonenumber needs to be verified first")
        }
      }
      VerifyPhoneNumber(verification_code) -> {
        case user_registration.state {
          Pending if verification_code == user_registration.verification_code ->
            Ok([PhoneNumberVerified])
          Pending if verification_code != user_registration.verification_code ->
            Error("Code mismatch")
          _ -> Error("Number was already verified")
        }
      }
    }
  }
}

pub fn user_registration_event_handler() -> signal.EventHandler(
  UserRegistration,
  UserRegistrationEvent,
) {
  fn(
    user_registration: UserRegistration,
    event: signal.Event(UserRegistrationEvent),
  ) {
    let payload = event.data
    case payload {
      PhoneNumberVerified ->
        UserRegistration(..user_registration, state: PhoneVerified)
      UserRegistrationCompleted(full_name) -> {
        UserRegistration(..user_registration, state: Completed(full_name))
      }
      UserRegistrationCreated(user_handle, phone_number, verification_code) -> {
        // no error handling here. We just crash if things go wrong!
        UserRegistration(user_handle, phone_number, verification_code, Pending)
      }
    }
  }
}

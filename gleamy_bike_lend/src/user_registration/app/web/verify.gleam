import gleam/http.{Get, Post}
import gleam/list
import gleam/result
import gleam/string_builder
import signal
import user_registration/application.{type UserRegistrationAggregate}
import user_registration/domain
import wisp.{type Request, type Response}

pub fn show_form(user_handle) {
  let html =
    string_builder.from_string(
      "<form method='post' action='/user_registration/verify/"
      <> user_handle
      <> "'>      
        </label>
        <label>Registration Number:
          <input type='text' name='verification-code'>
        </label>
        <input type='submit' value='Submit'>
      </form>",
    )
  wisp.ok()
  |> wisp.html_body(html)
}

pub fn verify_phone_number(
  req: Request,
  user_handle: String,
  user_registrations: UserRegistrationAggregate,
) {
  use formdata <- wisp.require_form(req)
  let verification_code = list.key_find(formdata.values, "verification-code")
  case verification_code {
    Ok(code) -> {
      let assert Ok(user_registration) =
        signal.aggregate(user_registrations, user_handle)
      let assert Ok(_) =
        signal.handle_command(user_registration, domain.VerifyPhoneNumber(code))
      wisp.redirect("/user_registration/complete/" <> user_handle)
    }
    _ -> show_form(user_handle)
  }
}

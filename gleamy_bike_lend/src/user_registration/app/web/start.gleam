import gleam/http.{Get, Post}
import gleam/list
import gleam/result
import gleam/string_builder
import signal
import user_registration/application.{type UserRegistrationAggregate}
import user_registration/domain
import wisp.{type Request, type Response}

pub fn show_form(user_handle, phone_numner) {
  let html =
    string_builder.from_string(
      "<form method='post' action='/user_registration/start'>
        <label>User Handle:
          <input type='text' name='user-handle' value='" <> user_handle <> "'>
        </label>
        <label>Phone Number:
          <input type='text' name='phone-number' value='" <> phone_numner <> "'>
        </label>
        <input type='submit' value='Submit'>
      </form>",
    )
  wisp.ok()
  |> wisp.html_body(html)
}

pub fn start_user_registration(
  req: Request,
  user_registrations: UserRegistrationAggregate,
) -> Response {
  use formdata <- wisp.require_form(req)
  let params = {
    use user_handle <- result.try(list.key_find(formdata.values, "user-handle"))
    use phone_number <- result.try(list.key_find(
      formdata.values,
      "phone-number",
    ))
    Ok(#(user_handle, phone_number))
  }
  case params {
    Ok(#(user_handle, phone_number)) -> {
      let assert Ok(handle) = domain.user_handle(user_handle)
      let assert Ok(phone_number) = domain.phone_number(phone_number)

      let assert Ok(aggregate) = signal.create(user_registrations, user_handle)
      let assert Ok(_) =
        signal.handle_command(
          aggregate,
          domain.CreateUserRegistration(handle, phone_number),
        )
      wisp.redirect("/user_registration/verify/" <> user_handle)
    }
    // TODO form to request for reasons ....
    _ -> show_form("", "")
  }
}

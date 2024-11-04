import gleam/list
import gleam/string_builder
import signal
import user_registration/application.{type UserRegistrationAggregate}
import user_registration/domain
import wisp.{type Request, type Response}

pub fn show_form(user_handle) {
  let html =
    string_builder.from_string(
      "<form method='post' action='/user_registration/complete/"
      <> user_handle
      <> "''>
        <label>First Name:
          <input type='text' name='first-name' >
        </label>
        <label>Last Name:
          <input type='text' name='last-name'>
        </label>        
        <input type='submit' value='Submit'>
      </form>",
    )
  wisp.ok()
  |> wisp.html_body(html)
}

pub fn complete_registration(
  req: Request,
  user_handle: String,
  user_registrations: UserRegistrationAggregate,
) {
  use formdata <- wisp.require_form(req)
  let first_name = list.key_find(formdata.values, "first-name")
  let last_name = list.key_find(formdata.values, "last-name")
  case first_name, last_name {
    Ok(first), Ok(last) -> {
      let assert Ok(user_registration) =
        signal.aggregate(user_registrations, user_handle)
      let assert Ok(valid_name) = domain.full_name(first, last)
      let assert Ok(_) =
        signal.handle_command(
          user_registration,
          domain.CompleteUserRegistration(valid_name),
        )
      wisp.redirect("/user_registration/success/" <> user_handle)
    }
    _, _ -> show_form(user_handle)
  }
}

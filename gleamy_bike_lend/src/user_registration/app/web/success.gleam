import gleam/string_builder
import wisp

pub fn show_form() {
  let html =
    string_builder.from_string(
      "
        <h2> DONE<</h2>
        <a href='/user_registration/start'>Play again!<a>
  ",
    )
  html
  wisp.ok()
  |> wisp.html_body(html)
}

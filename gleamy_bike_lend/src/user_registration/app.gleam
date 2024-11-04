import gleam/erlang/process
import mist
import user_registration/app/router
import user_registration/app/web
import wisp
import wisp/wisp_mist

pub fn main(user_registrations) {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let ctx = web.Context(user_registrations)
  let assert Ok(_) =
    wisp_mist.handler(router.handle_request(_, ctx), secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}

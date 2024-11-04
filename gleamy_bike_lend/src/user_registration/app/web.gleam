import gleam/erlang/process.{type Subject}
import user_registration/application
import user_registration/domain
import wisp

// A new Context type, which holds any additional data that the request handlers
// need in addition to the request.
//
// Here it is holding a database connection, but it could hold anything else
// such as API keys, IO performing functions (so they can be swapped out in
// tests for mock implementations), configuration, and so on.
//
pub type Context {
  Context(user_registrations: application.UserRegistrationAggregate)
}

pub fn middleware(
  req: wisp.Request,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  handle_request(req)
}

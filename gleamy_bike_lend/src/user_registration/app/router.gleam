import gleam/http.{Get, Post}
import user_registration/app/web.{type Context}
import user_registration/app/web/complete
import user_registration/app/web/start
import user_registration/app/web/success
import user_registration/app/web/verify
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)

  // A new `app/web/people` module now contains the handlers and other functions
  // relating to the People feature of the application.
  //
  // The router module now only deals with routing, and dispatches to the
  // feature modules for handling requests.
  // 
  //let query = wisp.get_query(req)
  case req.method, wisp.path_segments(req) {
    Get, ["user_registration", "start"] -> start.show_form("", "")
    Post, ["user_registration", "start"] ->
      start.start_user_registration(req, ctx.user_registrations)
    Get, ["user_registration", "verify", user_handle] -> {
      // we just show it, even if ot does not exist! ;)
      verify.show_form(user_handle)
    }
    Post, ["user_registration", "verify", user_handle] -> {
      verify.verify_phone_number(req, user_handle, ctx.user_registrations)
    }
    Get, ["user_registration", "complete", user_handle] -> {
      complete.show_form(user_handle)
    }
    Post, ["user_registration", "complete", user_handle] -> {
      complete.complete_registration(req, user_handle, ctx.user_registrations)
    }
    Get, ["user_registration", "success", user_handle] -> {
      success.show_form()
    }
    _, _ -> wisp.not_found()
  }
}

(* Logging *)
let https_src = Logs.Src.create "https" ~doc:"HTTPS server"

module Https_log = (val Logs.src_log https_src : Logs.LOG)

module Make () = struct
  (* given a URI, find the appropriate file,
   * and construct a response with its contents. *)
  let dispatcher minimal_http =
    (* let hostname = Key_gen.hostname () in *)
    (* match Uri.host uri with *)
    (* | Some host when String.equal host hostname -> *)
        begin match Minimal_http.target minimal_http with
        | "/" ->
         (*   let header =
              Cohttp.Header.init_with "Strict-Transport-Security" "max-age=31536000"
              in *)
            let mimetype = Magic_mime.lookup "index.html" in
            let headers = Minimal_http.Headers.empty in
            let headers = Minimal_http.Headers.add_content_type headers mimetype in
            let body = Html.index in
            Minimal_http.response minimal_http ~status:`OK ~body ~headers
        | _ ->
            let body = "" in
            let headers = Minimal_http.Headers.empty in
            Minimal_http.response minimal_http ~status:`Not_found ~body ~headers
        end
(*    | None | Some _ ->
        let new_uri = Uri.with_host uri (Some hostname) in
        Https_log.info (fun f ->
          f "[%s] -> [%s]" (Uri.to_string uri) (Uri.to_string new_uri));
        let headers = Cohttp.Header.init_with "location" (Uri.to_string new_uri) in
        S.respond ~headers ~status:`Moved_permanently ~body:`Empty ()
*)

  let error minimal_http_error =
    Minimal_http.error_response minimal_http_error
      ~status:`Not_found ~headers:Minimal_http.Headers.empty ~body:""
end

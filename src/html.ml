let html_to_string html =
  Format.asprintf "%a" (Tyxml.Html.pp ~indent:true ()) html

let index =
  html_to_string @@
  let open Tyxml.Html in
  html
    (head (title (txt "exn.st")) [
       meta ~a:[a_charset "utf-8"] ();
     ])
    (body ~a:[a_style "max-width: 38em; margin: 0px auto; padding: 2em;"] [
       header [
         h1 [txt "Kate's world"];
       ];
       main ~a:[a_lang "en"] [
         p [txt "something something"];
       ];
       footer ~a:[a_style "padding-top: 5em;"] [
         small [txt "Powered by MirageOS / exn.st v0.2.0~beta15"];
       ];
     ])

(* This file is part of Learn-OCaml.
 *
 * Copyright (C) 2018 OCamlPro.
 *
 * Learn-OCaml is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * Learn-OCaml is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>. *)

open Cmdliner
open Arg

let sync_dir =
  value & opt string "./sync" & info ["sync-dir"] ~docv:"DIR" ~doc:
    "Directory where to store user sync tokens"

let default_http_port = 8080
let default_https_port = 8443

let cert =
  value & opt (some string) None &
  info ["cert"] ~docv:"BASENAME" ~env:(Arg.env_var "LEARNOCAML_CERT") ~doc:
    "HTTPS certificate: this option turns on HTTPS, and requires files \
     $(i,BASENAME.pem) and $(i,BASENAME.key) to be present. They will be \
     used as the server certificate and key, respectively. A passphrase \
     may be asked on the terminal if the key file is encrypted."

let port =
  value & opt (some int) None &
  info ["port";"p"] ~docv:"PORT" ~env:(Arg.env_var "LEARNOCAML_PORT") ~doc:
    (Printf.sprintf
       "The TCP port on which to run the server. Defaults to %d, or %d if \
        HTTPS is enabled."
       default_http_port default_https_port)

type t = {
  sync_dir: string;
  cert: string option;
  port: int;
}

let term app_dir =
  let apply app_dir sync_dir port cert =
    Learnocaml_store.static_dir := app_dir;
    Learnocaml_store.sync_dir := sync_dir;
    let port = match port, cert with
      | Some p, _ -> p
      | None, Some _ -> default_https_port
      | None, None -> default_http_port
    in
    Learnocaml_server.cert_key_files :=
      (match cert with
       | Some base -> Some (base ^ ".pem", base ^ ".key");
       | None -> None);
    Learnocaml_server.port := port;
    { sync_dir; port; cert }
  in
  (* warning: if you add any options here, remember to pass them through when
     calling the native server from learn-ocaml main *)
  Term.(const apply $app_dir $sync_dir $port $cert)

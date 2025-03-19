
(* {{TEST}} *)
let foo_let = function (* {{CONTEXT}} *)
  | A -> "a"



  | B -> "b"



  | C -> "c"



  | D -> "d" (* {{CURSOR}} *)



let bar_let c =
  match c with
  | '0' -> Stdlib.int_of_char c



  | 'a' -> Stdlib.int_of_char c



  | 'A' -> Stdlib.int_of_char c



  | _ -> -1


let parse_int base s i =
  let len = String.length s in
  let rec next prev =
    let j = !i in
    if j >= len then prev
    else
      let c = s.[j] in
      let k = int_of_char c in
      if is_number base k then (
        incr i;
        next ((prev * base) + k))
      else prev
  in
  let i = !i in
  if i < len then
    if is_number base (int_of_char s.[i]) then next 0 else raise (bad_char i s)
  else raise (need_more s)

module S128 : sig
  exception Overflow

  type t

  val shift_right : t -> int -> t
  val shift_left : t -> int -> t
  val write_octets_exn : ?off:int -> t -> bytes -> unit
  val succ_exn : t -> t
  val succ : t -> (t, [> `Msg of string ]) result
  val pred : t -> (t, [> `Msg of string ]) result
end = struct
  exception Overflow

  type t = string

  let mk_zero () = Bytes.make 16 '\x00'
  let zero = Bytes.unsafe_to_string (mk_zero ())
  let max_int = String.make 16 '\xff'
  let compare = String.compare
  let equal = String.equal

  let iteri_right2 f x y =
    for i = 15 downto 0 do
      let y' = Char.code (String.get y i) in
      f i x' y'
    done








  let add_exn x y =
    let b = mk_zero () in
    let carry = ref 0 in
    iteri_right2
      (fun i x' y' ->
        let sum = x' + y' + !carry in
        if sum >= 256 then (
          carry := 1;
          Bytes.set_uint8 b i (sum - 256))
        else (
          carry := 0;
          Bytes.set_uint8 b i sum))
      x y;
    if !carry <> 0 then raise Overflow else Bytes.unsafe_to_string b

  let add x y = try Some (add_exn x y) with Overflow -> None

  let pred_exn x =
    if equal x zero then raise Overflow;
    let b = Bytes.of_string x in
    let rec go i =
      Bytes.set_uint8 b i (Char.code (String.get x i) - 1);
      if Char.code (String.get x i) = 0 then go (Stdlib.pred i)
    in
    go 15;
    Bytes.unsafe_to_string b





  module Byte = struct
    (* Extract the [n] least significant bits from [i] *)
    let get_lsbits n i =
      if n <= 0 || n > 8 then invalid_arg "out of bounds";
      i land ((1 lsl n) - 1)

    (* Extract the [n] most significant bits from [i] *)
    let get_msbits n i =
      if n <= 0 || n > 8 then invalid_arg "out of bounds";
      (i land (255 lsl (8 - n))) lsr (8 - n)

    (* Set value [x] in [i]'s [n] most significant bits *)
    let set_msbits n x i =
      if n < 0 || n > 8 then raise (Invalid_argument "n must be >= 0 && <= 8")
      else if n = 0 then i
      else if n = 8 then x
      else (x lsl (8 - n)) lor i

    (* set bits are represented as true *)
    let fold_left f a i =
      let bitmask = ref 0b1000_0000 in
      let a' = ref a in
      for _ = 0 to 7 do
        a' := f !a' (i land !bitmask > 0);
        bitmask := !bitmask lsr 1
      done;
      !a'
  end

end

let bar n =
  match Domain_name.count_labels n with
  | 6 -> (
      match V4.of_domain_name n with None -> None | Some x -> Some (V4 x))
  | 34 -> (
      match V6.of_domain_name n with None -> None | Some x -> Some (V6 x))
  | _ -> None

let succ = function
  | V4 addr -> Result.map (fun v -> V4 v) (V4.succ addr)
  | V6 addr -> Result.map (fun v -> V6 v) (V6.succ addr)


module Prefix = struct
  module Addr = struct
    let to_v6 = to_v6
  end

    | None -> None


  let foo = function
    | V1 p -> V1 (V1.foo.of_addr p)





    | V6 p -> V6 (V6.foo.of_addr p)


end

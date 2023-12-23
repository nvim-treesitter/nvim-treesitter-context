
# Initiate a response handler with pre-filled values.
# @category Internet
# @method content_type Set `"Content-Type"` header
# @method data Set response data.
# @method headers Replace response headers.
# @method header Set a single header on the response
# @method json Set content-type to json and data to `json.stringify` of the argument
# @method redirect Set `status_code` and `Location:` header for a HTTP redirect response
# @method html Set content-type to html and data to argument value
# @method http_version Set http protocol version
# @method status_code Set response status code
# @method status_message Set response status message
def http.response(
  ~http_version="1.1",
  ~status_code=null(),
  ~status_message=null(),
  ~headers=[],
  ~content_type=null(),
  ~data=getter("")
) =
  status_code =
    status_code
      ??
        if
          http_version == "1.1"
        and
          headers["expect"] == "100-continue"
        and
          getter.get(data) == ""
        then
          100
        else
          200
        end

  http_version = ref(http_version)
  status_code = ref(status_code)
  status_message = ref(status_message)
  headers = ref(headers)
  content_type = ref(content_type)
  data = ref(data)
  status_sent = ref(false)
  headers_sent = ref(false)
  data_sent = ref(false)
  response_ended = ref(false)

  def mk_status() =
    status_sent := true
    http_version = http_version()
    status_code = status_code()
    status_code =
      if
        status_code == 100 and getter.get(data()) != ""
      then
        200
      else
        status_code
      end

    status_message = status_message() ?? http.codes[status_code]
    "HTTP/#{http_version} #{status_code} #{status_message}\r\n"
  end

  def mk_headers() =
    headers_sent := true
    headers = headers()
    content_type = content_type()
    data = data()
    headers =
      if
        getter.is_constant(data)
      then
        data = getter.get(data)
        if
          data != ""
        then
          ("Content-Length", "#{string.length(data)}")::headers
        else
          headers
        end
      else
        ("Transfer-Encoding", "chunked")::headers
      end

    headers =
      if
        null.defined(content_type) and null.get(content_type) != ""
      then
        ("Content-type", null.get(content_type))::headers
      else
        headers
      end

    headers = list.map(fun (v) -> "#{fst(v)}: #{snd(v)}", headers)
    headers = string.concat(separator="\r\n", headers)
    headers = if headers != "" then "#{headers}\r\n" else "" end
    "#{headers}\r\n"
  end

  def mk_data() =
    data_sent := true
    data = data()
    if
      getter.is_constant(data)
    then
      response_ended := true
      getter.get(data)
    else
      data = getter.get(data)
      response_ended := data == ""
      "#{string.hex_of_int(string.length(data))}\r\n#{data}\r\n"
    end
  end

  def response() =
    if
      response_ended()
    then
      ""
    elsif not status_sent() then mk_status()
    elsif not headers_sent() then mk_headers()
    else
      mk_data()
    end
  end

  def attr_method(sent, attr) =
    def set(v) =
      if
        sent()
      then
        error.raise(
          error.invalid, "HTTP response has already been sent for this value!"
        )
      end

      attr := v
    end

    def get() =
      attr()
    end

    set.{current=get}
  end

  def header(k, v) =
    headers := (k, v)::headers()
  end

  code = status_code

  def redirect(~status_code=301, location) =
    if
      status_sent()
    then
      error.raise(
        error.invalid, "HTTP response has already been sent for this value!"
      )
    end

    code := status_code
    header("Location", location)
  end

  def json(~compact=true, v) =
    if
      headers_sent()
    then
      error.raise(
        error.invalid, "HTTP response has already been sent for this value!"
      )
    end

    content_type := "application/json; charset=utf-8"
    data := json.stringify(v, compact=compact) ^ "\n"
  end

  def html(d) =
    if
      headers_sent()
    then
      error.raise(
        error.invalid, "HTTP response has already been sent for this value!"
      )
    end

    content_type := "text/html"
    data := d
  end

  def send_status(socket) =
    if not status_sent() then socket.write(mk_status()) end
  end

  def multipart_form(~boundary=null(), contents) =
    if
      headers_sent()
    then
      error.raise(
        error.invalid, "HTTP response has already been sent for this value!"
      )
    end

    form_data = http.multipart_form_data(boundary=boundary, contents)
    content_type := "multipart/form-data; boundary=#{form_data.boundary}"
    data := form_data.contents
  end

  response.{
    http_version=attr_method(status_sent, http_version),
    status_code=attr_method(status_sent, status_code),
    status_message=attr_method(status_sent, status_message),
    headers=attr_method(headers_sent, headers),
    header=header,
    redirect=redirect,
    json=json,
    html=html,
    content_type=attr_method(headers_sent, content_type),
    multipart_form=multipart_form,
    data=attr_method(data_sent, data),
    send_status=send_status,
    status_sent={status_sent()}
  }
end

# @flag hidden
upload_file_fn =
  fun (
    ~name,
    ~content_type,
    ~headers,
    ~boundary,
    ~filename,
    ~file,
    ~contents,
    ~timeout,
    ~redirect,
    url,
    fn
  ) ->
    begin
      if
        not null.defined(filename) and not null.defined(file)
      then
        error.raise(
          error.http, "At least one of: `file` or `filename` must be defined!"
        )
      end

      if
        null.defined(file) and null.defined(contents)
      then
        error.raise(
          error.http, "Only one of: `contents` or `file` must be defined!"
        )
      end


      # Massage parameters
      filename =
        null.defined(filename)
        ? null.get(filename) : string(path.basename(null.get(file)))

      contents =
        null.defined(contents)
        ? null.get(contents) : getter(stdlib_file.read(null.get(file)))


      # Create query
      content_type = content_type ?? "application/octet-stream"
      data =
        http.multipart_form_data(
          boundary=boundary,
          [
            {
              name=name,
              attributes=[("filename", filename)],
              headers=[("Content-Type", content_type)],
              contents=contents
            }
          ]
        )

      headers =
        (
          "Content-Type",
          "multipart/form-data; boundary=#{data.boundary}"
        )::headers

      fn(
        headers=headers,
        timeout=timeout,
        redirect=redirect,
        data=data.contents,
        url
      )
    end

# Send a file via POST request encoded in multipart/form-data. The contents can
# either be directly specified (with the `contents` argument) or taken from a
# file (with the `file` argument).
# @category Internet
# @param ~name Name of the field field
# @param ~content_type Content-type (mime) for the file.
# @param ~headers Additional headers.
# @param ~boundary Specify boundary to use for multipart/form-data.
# @param ~filename File name sent in the request.
# @param ~file File whose contents is to be sent in the request.
# @param ~contents Contents of the file sent in the request.
# @param ~timeout Timeout in seconds.
# @param ~redirect Follow reidrections.
# @param url URL to post to.
def http.post.file(
  ~name="file",
  ~content_type=null(),
  ~headers=[],
  ~boundary=null(),
  ~filename=null(),
  ~file=null(),
  ~contents=null(),
  ~timeout=null(),
  ~redirect=true,
  url
) =
  upload_file_fn(
    name=name,
    content_type=content_type,
    headers=headers,
    boundary=boundary,
    filename=filename,
    file=file,
    contents=contents,
    timeout=timeout,
    redirect=redirect,
    url,
    http.post
  )
end

# Send a file via PUT request encoded in multipart/form-data. The contents can
# either be directly specified (with the `contents` argument) or taken from a
# file (with the `file` argument).
# @category Internet
# @param ~name Name of the field field
# @param ~content_type Content-type (mime) for the file.
# @param ~headers Additional headers.
# @param ~boundary Specify boundary to use for multipart/form-data.
# @param ~filename File name sent in the request.
# @param ~file File whose contents is to be sent in the request.
# @param ~contents Contents of the file sent in the request.
# @param ~timeout Timeout in seconds.
# @param ~redirect Follow reidrections.
# @param url URL to put to.
def http.put.file(
  ~name="file",
  ~content_type=null(),
  ~headers=[],
  ~boundary=null(),
  ~filename=null(),
  ~file=null(),
  ~contents=null(),
  ~timeout=null(),
  ~redirect=true,
  url
) =
  upload_file_fn(
    name=name,
    content_type=content_type,
    headers=headers,
    boundary=boundary,
    filename=filename,
    file=file,
    contents=contents,
    timeout=timeout,
    redirect=redirect,
    url,
    http.put
  )
end

# Extract the content-type header
# @category Internet
def http.headers.content_type(headers) =
  mime =
    try
      list.find(
        fun (v) ->
          begin
            let (header_name, _) = v
            string.case(lower=true, header_name) == "content-type"
          end,
        headers
      )
    catch _ : [error.not_found] do
      null()
    end

  mime = null.map(snd, mime)
  null.map(
    fun (mime) ->
      begin
        let [mime, ...args] =
          list.map(string.trim, string.split(separator=";", mime))

        def parse_arg(arg) =
          let [name, ...value] = string.split(separator="=", arg)
          (name, string.unquote(string.concat(separator="=", value)))
        end

        {mime=mime, args=list.map(parse_arg, args)}
      end,
    mime
  )
end

# Extract the content-disposition header
# @category Internet
def http.headers.content_disposition(headers) =
  content_disposition =
    try
      list.find(
        fun (v) ->
          begin
            let (header_name, _) = v
            string.case(lower=true, header_name) == "content-disposition"
          end,
        headers
      )
    catch _ : [error.not_found] do
      null()
    end

  def parse_arg(arg) =
    let [name, ...value] = string.split(separator="=", arg)
    (name, string.unquote(string.concat(separator="=", value)))
  end

  def parse_filename(args) =
    plain_filename = args["filename"]
    plain_filename = plain_filename == "" ? null() : plain_filename
    encoded_filename = args["filename*"]
    encoded_filename = encoded_filename == "" ? null() : encoded_filename
    encoded_filename =
      null.map(
        fun (encoded_filename) ->
          begin
            let [encoding, _, filename] =
              string.split(separator="'", encoded_filename)

            string.recode(in_enc=encoding, filename)
          end,
        encoded_filename
      )

    filename =
      null.defined(encoded_filename) ? encoded_filename : plain_filename

    filename =
      null.map(fun (filename) -> url.decode(string.unquote(filename)), filename)

    (
      filename,
      list.filter(
        fun (v) -> fst(v) != "filename" and fst(v) != "filename*", args
      )
    )
  end

  null.map(
    fun (v) ->
      begin
        let (_, header_value) = v
        let [type, ...args] =
          list.map(string.trim, string.split(separator=";", header_value))

        args = list.map(parse_arg, args)
        let (filename, args) = parse_filename(args)
        let (name, args) = parse_name(args)
        ({type=type, filename=filename, name=name, args=args} : {
          type: string,
          filename?: string,
          name?: string,
          args: [(string*string?)]
        })
      end,
    content_disposition
  )
end

# Generate DTMF tones.
# @flag extra
# @category Source / Sound synthesis
# @param ~duration Duration of a tone (in seconds).
# @param ~delay Dealy between two successive tones (in seconds).
# @param dtmf String describing DTMF tones to generates: it should contains characters 0 to 9, A to D, or * or #.
def replaces dtmf(~duration=0.1, ~delay=0.05, dtmf)
  l = ref([])
  for i = 0 to string.length(dtmf) - 1 do
    c = string.sub(dtmf, start=i, length=1)
    let (row, col) =
      if c == "1" then
        (697., 1209.)
      elsif c == "2" then
        (697., 1336.)
      elsif c == "3" then
        (697., 1477.)
      elsif c == "A" then
        (697., 1633.)
      elsif c == "4" then
        (770., 1209.)
      elsif c == "5" then
        (770., 1336.)
      elsif c == "6" then
        (770., 1477.)
      elsif c == "B" then
        (770., 1633.)
      elsif c == "7" then
        (852., 1209.)
      elsif c == "8" then
        (852., 1336.)
      elsif c == "9" then
        (852., 1477.)
      elsif c == "C" then
        (852., 1633.)
      elsif c == "*" then
        (941., 1209.)
      elsif c == "0" then
        (941., 1336.)
      elsif c == "#" then
        (941., 1477.)
      elsif c == "D" then
        (941., 1633.)
      else
        (0., 0.)
      end
    s = add([sine(row, duration=duration), sine(col, duration=duration)])
    l := blank(duration=delay) :: l()
    l := s :: l()
  end
  l = list.rev(l())
  sequence(l)
end

def erathostenes(n)
  l = list.init(n-2, fun (i) -> i+2)
  l = ref(l)
  p = ref([])
  while not list.is_empty(l()) do
    i = list.hd(default=0, l())
    p := list.add(i, p())
    l := list.filter(fun (j) -> j mod i != 0, l())
  end
  list.rev(p())
end

time("Erathostenes (imperative)", {erathostenes(10000)})

def erathostenes(n)
  def rec aux(p, l)
    list.case(l, p, fun (i, l) -> aux(list.add(i, p), list.filter(fun (j) -> j mod i != 0, l)))
  end
  l = list.init(n-2, fun (i) -> i+2)
  list.rev(aux([], l))
end

time("Erathostenes (recursive)", {erathostenes(10000)})

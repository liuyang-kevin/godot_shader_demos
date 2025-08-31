# WebServer.gd
# ds生成的, 基本逻辑对, 但是代理不出网页, 先放着
extends SceneTree

var tcp_server : TCPServer
var port : int = 8080
var web_root : String = "."

func _init():
    # 解析命令行参数
    var args = OS.get_cmdline_user_args()
    parse_arguments(args)
    
    # 创建 TCP 服务器
    tcp_server = TCPServer.new()
    
    # 启动服务器
    if tcp_server.listen(port) == OK:
        print("Godot Web服务器已启动 (Godot 4.x)")
        print("端口: " + str(port))
        print("根目录: " + ProjectSettings.globalize_path(web_root))
        print("访问地址: http://localhost:" + str(port))
        print("按 Ctrl+C 停止服务器")
    else:
        push_error("无法启动Web服务器，端口可能被占用")
        quit(1)

func parse_arguments(args: PackedStringArray):
    for i in range(args.size()):
        if args[i] == "--port" && i + 1 < args.size():
            port = int(args[i + 1])
        elif args[i] == "--root" && i + 1 < args.size():
            web_root = args[i + 1]

func _idle(delta):
    # 接受新的客户端连接
    if tcp_server.is_listening():
        var client : StreamPeerTCP = tcp_server.take_connection()
        if client:
            handle_client(client)
    
    return true

func handle_client(client: StreamPeerTCP):
    # 读取客户端请求
    var request_data = PackedByteArray()
    while client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
        var available = client.get_available_bytes()
        if available > 0:
            var chunk = client.get_data(available)
            if chunk[0] == OK:
                request_data.append_array(chunk[1])
        
        # 简单的请求结束检测（查找空行）
        if request_data.size() > 4:
            var request_text = request_data.get_string_from_utf8()
            if "\r\n\r\n" in request_text or "\n\n" in request_text:
                break
    
    if request_data.size() == 0:
        return
    
    var request_text = request_data.get_string_from_utf8()
    var request_lines = request_text.split("\n")
    
    if request_lines.size() == 0:
        return
    
    # 解析 HTTP 请求行
    var request_line = request_lines[0].strip_edges()
    var request_parts = request_line.split(" ")
    if request_parts.size() < 2:
        return
    
    var method = request_parts[0]
    var path = request_parts[1]
    
    # 处理请求
    if path == "/":
        path = "/index.html"
    
    var file_path = web_root + path
    var response = ""
    
    if FileAccess.file_exists(file_path):
        var file = FileAccess.open(file_path, FileAccess.READ)
        if file:
            var content = file.get_as_text()
            file.close()
            
            response = "HTTP/1.1 200 OK\r\n"
            response += "Content-Type: " + get_content_type(file_path) + "\r\n"
            response += "Content-Length: " + str(content.length()) + "\r\n"
            response += "Connection: close\r\n"
            response += "\r\n"
            response += content
        else:
            response = create_error_response(500, "Internal Server Error")
    else:
        response = create_error_response(404, "Not Found: " + path)
    
    # 发送响应
    client.put_data(response.to_utf8_buffer())
    client.disconnect_from_host()

func get_content_type(path: String) -> String:
    var extension = path.get_extension()
    match extension:
        "html": return "text/html"
        "js": return "application/javascript"
        "css": return "text/css"
        "wasm": return "application/wasm"
        "png": return "image/png"
        "jpg", "jpeg": return "image/jpeg"
        "gif": return "image/gif"
        "json": return "application/json"
        _: return "application/octet-stream"

func create_error_response(code: int, message: String) -> String:
    var html = "<html><body><h1>" + str(code) + " - " + message + "</h1></body></html>"
    var response = "HTTP/1.1 " + str(code) + " " + message + "\r\n"
    response += "Content-Type: text/html\r\n"
    response += "Content-Length: " + str(html.length()) + "\r\n"
    response += "Connection: close\r\n"
    response += "\r\n"
    response += html
    return response

func _exit_tree():
    if tcp_server.is_listening():
        tcp_server.stop()
        print("Web服务器已停止")
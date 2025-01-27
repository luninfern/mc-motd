import net
import encoding.leb128

const motd_text = 'Welcome to the server!'
const motd = '{"version": {"name": "1.20.1", "protocol": 763}, "players": {"max": 20, "online": 5}, "description": {"text": "${motd_text}"}}'

fn main() {
	mut listen := net.listen_tcp(net.AddrFamily.ip, '0.0.0.0:25565', net.ListenOptions{})!
	for {
		mut conn := listen.accept() or { continue }
		mut buffer := []u8{len: 1024}
		conn.read(mut buffer)!
		length, size1 := leb128.decode_i32(buffer)
		_, size2 := leb128.decode_i32(buffer[size1..])
		data := buffer[size1 + size2..].clone()
		mut position := 0
		_, size3 := leb128.decode_i32(data)
		position += size3
		len, start := leb128.decode_i32(data[position..])
		position += start + len + 2
		state, _ := leb128.decode_i32(data[position..length - size2])
		if state == 1 {
			mut data2 := []u8{}
			data2 << leb128.encode_i32(0)
			data2 << leb128.encode_i32(i32(motd.len))
			data2 << motd.bytes()
			mut buf := []u8{}
			buf << leb128.encode_i32(i32(data2.len))
			buf << data2
			conn.write(buf) or {}
		}
	}
}

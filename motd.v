import net

const motd_text = 'Welcome to the server!'
const motd = '{"version": {"name": "1.20.1", "protocol": 763}, "players": {"max": 20, "online": 5}, "description": {"text": "${motd_text}"}}'

fn encode_varint(num int) []u8 {
	mut value := num
	mut bytes := []u8{}
	for {
		b := u8(value & 0x7F)
		value >>= 7
		if value != 0 {
			bytes << (b | 0x80)
		} else {
			bytes << b
			break
		}
	}
	return bytes
}

fn decode_varint(data []u8) (int, int) {
	mut value := 0
	mut shift := 0
	mut index := 0
	for {
		b := data[index]
		index++
		value |= u32(b & 0x7F) << shift
		shift += 7
		if (b & 0x80) == 0 {
			break
		}
	}
	return value, index
}

fn main() {
	mut listen := net.listen_tcp(net.AddrFamily.ip, '0.0.0.0:25565', net.ListenOptions{})!
	for {
		mut conn := listen.accept() or { continue }
		mut buffer := []u8{len: 1024}
		conn.read(mut buffer)!
		length, size1 := decode_varint(buffer)
		_, size2 := decode_varint(buffer[size1..])
		data := buffer[size1 + size2..].clone()
		mut position := 0
		_, size3 := decode_varint(data)
		position += size3
		len, start := decode_varint(data[position..])
		position += start + len + 2
		state, _ := decode_varint(data[position..length - size2])
		if state == 1 {
			mut data2 := []u8{}
			data2 << encode_varint(0)
			data2 << encode_varint(motd.len)
			data2 << motd.bytes()
			mut buf := []u8{}
			buf << encode_varint(data2.len)
			buf << data2
			conn.write(buf) or {}
		}
	}
}

class_name SequenceCsvCodec
extends RefCounted

## Codifica/decodifica linhas do exportador de sequências (campo de itens pode ter vírgulas).

const ITEMS_SEP := "|"


static func escape_field(value: String) -> String:
	if value.find(",") == -1 and value.find('"') == -1 and value.find("\n") == -1:
		return value
	return '"' + value.replace('"', '""') + '"'


static func items_field_from_backpack_csv(csv_text: String) -> String:
	var t := csv_text.strip_edges()
	if t.is_empty():
		return ""
	return t.replace(",", ITEMS_SEP).replace(" ", "")


static func backpack_csv_from_items_field(field: String) -> String:
	var t := field.strip_edges()
	if t.is_empty():
		return ""
	if t.find(ITEMS_SEP) != -1:
		var parts: PackedStringArray = PackedStringArray()
		for p in t.split(ITEMS_SEP, false):
			var s := p.strip_edges()
			if not s.is_empty():
				parts.append(s)
		return ", ".join(parts)
	return t


static func parse_csv_line(line: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var i := 0
	var n := line.length()
	var cell := ""
	var in_quotes := false
	while i < n:
		var ch := line[i]
		if in_quotes:
			if ch == '"':
				if i + 1 < n and line[i + 1] == '"':
					cell += '"'
					i += 2
					continue
				in_quotes = false
				i += 1
				continue
			cell += ch
			i += 1
			continue
		if ch == '"':
			in_quotes = true
			i += 1
			continue
		if ch == ",":
			out.append(cell)
			cell = ""
			i += 1
			continue
		cell += ch
		i += 1
	out.append(cell)
	return out
